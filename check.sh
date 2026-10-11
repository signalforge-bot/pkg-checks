#!/usr/bin/env bash
# Usage: check.sh <package> <mode: registry|open>  -> writes results/<pkg>-<mode>.json
set -u
p="$1"; mode="$2"; d=$(mktemp -d); cd "$d"; echo '{}' > package.json
s=$(date +%s%3N)
npm install "$p" --no-audit --no-fund --loglevel=http > log.txt 2>&1; irc=$?
e=$(date +%s%3N)
size=$(du -sk node_modules 2>/dev/null | cut -f1)
gyp=$(grep -c 'node-gyp' log.txt || true)
post=$(grep -cE 'postinstall|install script' log.txt || true)
hosts=$(grep -oE 'https?://[^/ ]+' log.txt | sort -u | grep -v registry.npmjs.org | jq -R . | jq -sc .)
rs=$(date +%s%3N); node -e "require('$p')" > run.txt 2>&1; rrc=$?; re=$(date +%s%3N)
mkdir -p "$GITHUB_WORKSPACE/results"
jq -n --arg p "$p" --arg m "$mode" --argjson irc $irc --argjson it $((e-s)) --argjson sz ${size:-0} \
  --argjson rrc $rrc --argjson rt $((re-rs)) --argjson h "$hosts" --argjson gyp $gyp --argjson post $post \
  '{package:$p,mode:$m,install:{ok:($irc==0),ms:$it,size_kb:$sz},first_run:{ok:($rrc==0),ms:$rt},
    network:{extra_hosts:$h,postinstall:($post>0)},native_build:{node_gyp:($gyp>0)}}' \
  > "$GITHUB_WORKSPACE/results/$p-$mode.json"
