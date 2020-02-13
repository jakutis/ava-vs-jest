#!/usr/bin/env bash

NS="1 2 4 8 16 32 64 128 256 512 1024"
ROOT="$1"
SRC="$(pwd)"
if [ -n "$ROOT" ]
then
  ROOT="$(realpath "$ROOT")"
else
  ROOT="$SRC"
fi
mkdir -p $ROOT || exit

pip3 install psrecord matplotlib csv2md --user
export PATH="$PATH:$HOME/.local/bin"

npm install
export PATH="$PATH:$SRC/node_modules/.bin"

function jest {
    BASE="$1"
    (FATJEST_COUNT="1" node ./node_modules/.bin/jest --maxWorkers=4 --silent "$BASE"'-tests/*' 1>"$BASE.stdout" 2>&1;echo $? > "$BASE.code") &
    psrecord --include-children --plot "$BASE.png" --log "$BASE.log" 1>/dev/null 2>&1 $!
}

function ava {
    BASE="$1"
    (FATJEST_COUNT="1" node ./node_modules/.bin/ava --concurrency=4 "$BASE"'-tests/*' 1>"$BASE.stdout" 2>&1;echo $? > "$BASE.code") &
    psrecord --include-children --plot "$BASE.png" --log "$BASE.log" 1>/dev/null 2>&1 $!
}

function runsome {
    CMD="$1"
    N="$2"
    BASE="$ROOT/result-$CMD-$N"

    mkdir "$BASE-tests"
    for I in $(seq 1 $N)
    do
      cp "$SRC/$CMD.spec.js" "$BASE-tests/test$I-$CMD.spec.js"
    done
    date +%s > "$BASE.start"
    $CMD "$BASE"
    date +%s > "$BASE.finish"
    TIME=$(($(cat "$BASE.finish") - $(cat "$BASE.start")))
    MAXRAM=$(cat "$BASE.log" | sed 's/\s\s*/ /g' |tail -n +2|cut -f 4 -d ' '|sort -n|tail -n 1)
    echo "$MAXRAM $TIME"
    if [ "$(cat "$BASE.code")" != "0" ]
    then
      rm $BASE.png
      echo $BASE >> $ROOT/failed
    fi
}

echo "N,ava,jest" > "$ROOT/memory.csv"
echo "N,ava,jest" > "$ROOT/multifile-duration.csv"
echo "N,ava,jest" > "$ROOT/memory-per-file.csv"
echo "N,ava,jest" > "$ROOT/time-per-file.csv"
for N in $NS
do
  echo "# $N"
  JEST=$(runsome "jest" "$N")
  JEST_R="${JEST%% *}"
  JEST_T="${JEST##* }"
  AVA=$(runsome "ava" "$N")
  AVA_R="${AVA%% *}"
  AVA_T="${AVA##* }"
  echo "$N,$AVA_R,$JEST_R" >> "$ROOT/memory.csv"
  echo "$N,$AVA_T,$JEST_T" >> "$ROOT/multifile-duration.csv"
  echo "$N,$(echo $AVA_R/$N|bc -l),$(echo $JEST_R/$N|bc -l)" >> "$ROOT/memory-per-file.csv"
  echo "$N,$(echo $AVA_T/$N|bc -l),$(echo $JEST_T/$N|bc -l)" >> "$ROOT/time-per-file.csv"
done

csv2md "$ROOT/memory.csv" > "$ROOT/memory.md"
gnuplot -e "set datafile separator ',';set grid;set term png;set output '$ROOT/memory.png';set ylabel 'max memory used, MB';set xlabel 'number of test files';plot '$ROOT/memory.csv' using 1:2 with lines title 'ava', '$ROOT/memory.csv' using 1:3 with lines title 'jest'"
csv2md "$ROOT/multifile-duration.csv" > "$ROOT/multifile-duration.md"
gnuplot -e "set datafile separator ',';set grid;set term png;set output '$ROOT/multifile-duration.png';set ylabel 'duration, s';set xlabel 'number of test files';plot '$ROOT/multifile-duration.csv' using 1:2 with lines title 'ava', '$ROOT/multifile-duration.csv' using 1:3 with lines title 'jest'"
csv2md "$ROOT/memory-per-file.csv" > "$ROOT/memory-per-file.md"
gnuplot -e "set datafile separator ',';set grid;set term png;set output '$ROOT/memory-per-file.png';set ylabel 'max mean memory per file used, MB';set xlabel 'number of test files';plot '$ROOT/memory-per-file.csv' every ::7 using 1:2 with lines title 'ava', '$ROOT/memory-per-file.csv' every ::7 using 1:3 with lines title 'jest'"
csv2md "$ROOT/time-per-file.csv" > "$ROOT/time-per-file.md"
gnuplot -e "set datafile separator ',';set grid;set term png;set output '$ROOT/time-per-file.png';set ylabel 'mean duration per file, s';set xlabel 'number of test files';plot '$ROOT/time-per-file.csv' every ::7 using 1:2 with lines title 'ava', '$ROOT/time-per-file.csv' every ::7 using 1:3 with lines title 'jest'"