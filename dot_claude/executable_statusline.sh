#!/usr/bin/env bash
# Claude Code status line, two rows:
#   user@host project ⎇ branch · PR · spend across all agents
#   model · effort │ context bar, % used, tokens │ prompt cache │ usage limit (or session cost)
# Reads the status JSON on stdin (https://code.claude.com/docs/en/statusline).

input=$(cat)
field() { jq -r "$1 // empty" <<<"$input"; }

reset=$'\033[0m'; dim=$'\033[2m'; bold=$'\033[1m'
red=$'\033[31m'; green=$'\033[32m'; yellow=$'\033[33m'; blue=$'\033[34m'; magenta=$'\033[35m'; cyan=$'\033[36m'
sep=" ${dim}│${reset} "
dot=" ${dim}·${reset} "
now=$(date +%s)

# Seconds as a short duration: 45s, 12m, 1h05m, 2d03h.
human() {
  local s=$1
  if (( s < 60 )); then printf '%ds' "$s"; return; fi
  if (( s < 3600 )); then printf '%dm' $(( s / 60 )); return; fi
  if (( s < 86400 )); then printf '%dh%02dm' $(( s / 3600 )) $(( s % 3600 / 60 )); return; fi
  printf '%dd%02dh' $(( s / 86400 )) $(( s % 86400 / 3600 ))
}

# Tokens as 950, 56K, 1.2M.
tokens() {
  awk -v n="$1" 'BEGIN {
    if (n >= 999500) { m = sprintf("%.1f", n / 1000000); sub(/\.0$/, "", m); printf "%sM", m }
    else if (n >= 1000) printf "%dK", n / 1000 + 0.5
    else printf "%d", n
  }'
}

# Green below the warn level, yellow below the alert level, red above.
level_color() {
  local value=$1 warn=$2 alert=$3
  if (( value >= alert )); then printf '%s' "$red"; return; fi
  if (( value >= warn )); then printf '%s' "$yellow"; return; fi
  printf '%s' "$green"
}

# Row 1: where am I. user@host, project folder, git branch, open PR.
dir=$(field '.workspace.current_dir'); dir=${dir:-$(field '.cwd')}; dir=${dir:-$PWD}
project_dir=$(field '.workspace.project_dir'); project_dir=${project_dir:-$dir}
host=$(uname -n); host=${host%%.*}
row1="${dim}$(whoami)@${host}${reset} ${bold}${blue}$(basename "$project_dir")${reset}"

worktree=$(field '.worktree.name')
[[ -n $worktree ]] && row1+=" ${dim}(worktree ${worktree})${reset}"

branch=$(git -C "$dir" branch --show-current 2>/dev/null)
[[ -n $branch ]] && row1+=" ${cyan}⎇ ${branch}${reset}"

pr=$(field '.pr.number')
if [[ -n $pr ]]; then
  row1+="${dot}${magenta}PR #${pr}${reset}"
  review=$(field '.pr.review_state')
  [[ -n $review ]] && row1+=" ${dim}${review}${reset}"
fi

# Spend across all agents: today, streak and month to date from llm-usage-metrics, shared by every
# session. A run costs ~2s of CPU, so a detached refresh rewrites a cache file at most every 2 minutes
# (it outlives this script, which Claude Code cancels on the next update) and the line shows the
# cached result. Hidden when that result is over 10 minutes old, e.g. after a suspend or past midnight.
if command -v llm-usage >/dev/null; then
  usage_cache=${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline/llm-usage
  if (( now - $(stat -c %Y "$usage_cache.lock" 2>/dev/null || echo 0) >= 120 )); then
    mkdir -p "${usage_cache%/*}"
    # stdin is closed so it reports only the totals; this script already shows the session.
    setsid -f flock -n "$usage_cache.lock" sh -c 'touch "$1.lock"
      out=$(llm-usage statusline </dev/null 2>/dev/null) && [ -n "$out" ] &&
        printf "%s\n" "$out" >"$1.tmp" && mv "$1.tmp" "$1"' sh "$usage_cache" </dev/null >/dev/null 2>&1
  fi
  if (( now - $(stat -c %Y "$usage_cache" 2>/dev/null || echo 0) < 600 )) && read -r spend <"$usage_cache"; then
    row1+="${dot}${dim}${spend}${reset}"
  fi
fi

# Row 2: model and effort.
model=$(field '.model.display_name')
effort=$(field '.effort.level')
row2="${bold}${magenta}${model:-Claude}${reset}"
[[ -n $effort ]] && row2+="${dot}${magenta}${effort}${reset}"

# Output speed, estimated from the transcript: output tokens ÷ time over the last 10 main-thread
# API responses of 50+ tokens. Time runs from the entry before a response to its last block, so it
# includes time to first token: end-to-end speed, roughly 30 % under raw generation speed.
# Hidden until there are 2 such responses.
transcript=$(field '.transcript_path')
if [[ -n $transcript && -r $transcript ]]; then
  tps=$(tail -n 400 "$transcript" | jq -nR '
    def ts: (.[0:19] + "Z" | fromdate) + ((.[20:23] | tonumber? // 0) / 1000);
    [inputs | fromjson? | select((.type == "user" or .type == "assistant") and .isSidechain != true and .timestamp != null)
      | {t: (.timestamp | ts), rid: (if .type == "assistant" then .requestId else null end), out: (.message.usage.output_tokens? // 0)}]
    | reduce .[] as $e ({prev: null, last_rid: null, reqs: []};
        if $e.rid == null then .
        elif (.reqs | length) > 0 and .reqs[-1].rid == $e.rid then .reqs[-1].end = $e.t | .reqs[-1].out = $e.out
        elif $e.rid == .last_rid or .prev == null then .  # request began before the window: skip it
        else .reqs += [{rid: $e.rid, start: .prev, end: $e.t, out: $e.out}] end
        | .prev = $e.t | .last_rid = ($e.rid // .last_rid))
    | [.reqs[] | select(.out >= 50 and .end > .start and .end - .start < 600)] | .[-10:]
    | if length < 2 then empty else (map(.out) | add) / (map(.end - .start) | add) | round end' 2>/dev/null)
  [[ -n $tps ]] && row2+="${dot}${dim}~${tps} tok/s${reset}"
fi

# Context: 10-cell bar, % used and tokens in use out of the window.
# The status JSON measures against the model's full window, so when an auto-compact window is
# set, measure against that instead. Precedence follows Claude Code: CLAUDE_CODE_AUTO_COMPACT_WINDOW,
# then modelSettings[model].autoCompactWindow, then autoCompactWindow ("auto" = the model's window).
# Clamped to 100K-1M and capped at the model's window. Only user settings are read.
used=$(field '.context_window.used_percentage')
size=$(field '.context_window.context_window_size | numbers | floor')
in_use=$(jq -r '.context_window.current_usage
  | if . == null then empty
    else ((.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)) | floor end' <<<"$input")
if [[ $CLAUDE_CODE_AUTO_COMPACT_WINDOW =~ ^[0-9]+ ]]; then
  compact_window=${BASH_REMATCH[0]}
else
  compact_window=$(jq -r --arg id "$(field '.model.id')" \
    '(.modelSettings[$id].autoCompactWindow // .autoCompactWindow) | numbers | floor' ~/.claude/settings.json 2>/dev/null)
fi
if [[ -n $compact_window && -n $in_use ]]; then
  (( compact_window < 100000 )) && compact_window=100000
  (( compact_window > 1000000 )) && compact_window=1000000
  [[ -n $size ]] && (( compact_window > size )) && compact_window=$size
  size=$compact_window
  used=$(( in_use * 100 / size ))
fi
if [[ -n $used ]]; then
  used=$(( $(printf '%.0f' "$used") )); (( used < 0 )) && used=0; (( used > 100 )) && used=100
  color=$(level_color "$used" 50 80)
  filled=$(( (used + 5) / 10 )); (( filled > 10 )) && filled=10
  bar=""
  for (( i = 0; i < 10; i++ )); do
    if (( i < filled )); then bar+="▰"; else bar+="▱"; fi
  done
  [[ -z $in_use && -n $size ]] && in_use=$(( size * used / 100 ))
  row2+="${sep}ctx ${color}${bar} ${used}%${reset}"
  [[ -n $in_use && -n $size ]] && row2+=" ${color}$(tokens "$in_use")${reset}${dim}/$(tokens "$size")${reset}"
fi

# Prompt cache: session hit rate and miss count, then time left while warm. Once cold: time since
# the last message and the tokens the next message writes back to the cache.
hit=$(field '.prompt_cache.hit_ratio')
if [[ -n $hit ]]; then
  pct=$(awk -v r="$hit" 'BEGIN { printf "%d", r * 100 + 0.5 }')
  color=$(level_color $(( 100 - pct )) 21 51)
  row2+="${sep}cache ${color}${pct}% hit${reset}"
  misses=$(field '.prompt_cache.misses | numbers')
  if [[ -n $misses ]] && (( misses > 0 )); then
    row2+=" ${yellow}${misses} miss$( (( misses > 1 )) && printf es)${reset}"
  fi
  warm=$(field '.prompt_cache.warm')
  expires=$(field '.prompt_cache.expires_at | numbers | floor')
  if [[ $warm == true && -n $expires ]] && (( expires > now )); then
    row2+="${dot}${green}warm $(human $(( expires - now )))${reset}"
  else
    cold="cold"
    if [[ -n $expires ]]; then
      ttl_s=300; [[ $(field '.prompt_cache.ttl') == 1h ]] && ttl_s=3600
      cold+=" · last msg $(human $(( now - (expires - ttl_s) ))) ago"
    fi
    recache=$(field '.prompt_cache.recache_tokens_if_cold | numbers | floor')
    [[ -n $recache ]] && cold+=" · recache $(tokens "$recache")"
    row2+="${dot}${yellow}${cold}${reset}"
  fi
fi

# Usage: the 5-hour subscription limit when there is one, otherwise the session cost.
limit=$(field '.rate_limits.five_hour.used_percentage')
if [[ -n $limit ]]; then
  limit=$(printf '%.0f' "$limit")
  row2+="${sep}5h $(level_color "$limit" 60 85)${limit}%${reset}"
  resets=$(field '.rate_limits.five_hour.resets_at | numbers | floor')
  [[ -n $resets ]] && (( resets > now )) && row2+=" ${dim}resets $(human $(( resets - now )))${reset}"
else
  cost=$(field '.cost.total_cost_usd')
  [[ -n $cost ]] && row2+="${sep}${dim}\$$(printf '%.2f' "$cost")${reset}"
fi

printf '%s\n%s' "$row1" "$row2"
