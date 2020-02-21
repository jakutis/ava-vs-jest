#!/usr/bin/env bash

NS="1 2 4 8 16 32 64 128 256 512 1024"

ENV="$1"
SRC="$(pwd)"
if [ -n "$2" ]
then
  ROOT="$2-$ENV"
else
  ROOT="$SRC-$ENV"
fi
pushd .
mkdir -p "$ROOT" || exit
cd "$ROOT"
ROOT="$(pwd)"
popd

pip3 install psrecord matplotlib csv2md --user
export PATH="$PATH:$(python3 -m site --user-base)/bin"

npm install
export PATH="$PATH:$SRC/node_modules/.bin"

function jest {
    BASE="$1"
    (FATJEST_COUNT="1" node ./node_modules/.bin/jest --env "$2" --maxWorkers=4 --silent "$BASE"'-tests/*' 1>"$BASE.stdout" 2>&1;echo $? > "$BASE.code") &
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
    ENV="$3"
    BASE="$ROOT/result-$CMD-$N"

    rm -rf "$BASE-tests"
    mkdir "$BASE-tests"
    for I in $(seq 1 $N)
    do
      cp "$SRC/$CMD-$ENV.spec.js" "$BASE-tests/test$I-$CMD.spec.js"
    done
    date +%s > "$BASE.start"
    $CMD "$BASE" "$ENV"
    date +%s > "$BASE.finish"
    TIME=$(($(cat "$BASE.finish") - $(cat "$BASE.start")))
    MAXMEMORY=$(cat "$BASE.log" | sed 's/\s\s*/ /g' |tail -n +2|cut -f 4 -d ' '|sort -n|tail -n 1)
    echo "$MAXMEMORY $TIME"
    if [ "$(cat "$BASE.code")" != "0" ]
    then
      rm $BASE.png
      echo $BASE >> $ROOT/failed
    fi
}

rm "$ROOT/memory."* "$ROOT/multifile-duration."* "$ROOT/memory-per-file."* "$ROOT/time-per-file."*
echo "files,AVA,Jest" > "$ROOT/memory.csv"
echo "files,AVA,Jest" > "$ROOT/multifile-duration.csv"
echo "files,AVA,Jest" > "$ROOT/memory-per-file.csv"
echo "files,AVA,Jest" > "$ROOT/time-per-file.csv"
echo "# observe-memory-multifile $ENV"
for N in $NS
do
  echo "## $N"
  echo "### jest"
  JEST=$(runsome "jest" "$N" "$ENV")
  JEST_R="${JEST%% *}"
  JEST_T="${JEST##* }"
  echo "### ava"
  AVA=$(runsome "ava" "$N" "$ENV")
  AVA_R="${AVA%% *}"
  AVA_T="${AVA##* }"
  echo "$N,$AVA_R,$JEST_R" >> "$ROOT/memory.csv"
  echo "$N,$AVA_T,$JEST_T" >> "$ROOT/multifile-duration.csv"
  echo "$N,$(echo $AVA_R/$N|bc -l),$(echo $JEST_R/$N|bc -l)" >> "$ROOT/memory-per-file.csv"
  echo "$N,$(echo $AVA_T/$N|bc -l),$(echo $JEST_T/$N|bc -l)" >> "$ROOT/time-per-file.csv"
done

csv2md "$ROOT/memory.csv" > "$ROOT/memory.md"
gnuplot -e "set datafile separator ',';set grid;set term png;set output '$ROOT/memory.png';set ylabel 'max memory used, MB';set xlabel 'number of test files';plot '$ROOT/memory.csv' using 1:2 with lines title 'AVA', '$ROOT/memory.csv' using 1:3 with lines title 'Jest'"
csv2md "$ROOT/multifile-duration.csv" > "$ROOT/multifile-duration.md"
gnuplot -e "set datafile separator ',';set grid;set term png;set output '$ROOT/multifile-duration.png';set ylabel 'duration, s';set xlabel 'number of test files';plot '$ROOT/multifile-duration.csv' using 1:2 with lines title 'AVA', '$ROOT/multifile-duration.csv' using 1:3 with lines title 'Jest'"
csv2md "$ROOT/memory-per-file.csv" > "$ROOT/memory-per-file.md"
gnuplot -e "set datafile separator ',';set grid;set term png;set output '$ROOT/memory-per-file.png';set ylabel 'max mean memory per file used, MB';set xlabel 'number of test files';plot '$ROOT/memory-per-file.csv' every ::7 using 1:2 with lines title 'AVA', '$ROOT/memory-per-file.csv' every ::7 using 1:3 with lines title 'Jest'"
csv2md "$ROOT/time-per-file.csv" > "$ROOT/time-per-file.md"
gnuplot -e "set datafile separator ',';set grid;set term png;set output '$ROOT/time-per-file.png';set ylabel 'mean duration per file, s';set xlabel 'number of test files';plot '$ROOT/time-per-file.csv' every ::7 using 1:2 with lines title 'AVA', '$ROOT/time-per-file.csv' every ::7 using 1:3 with lines title 'Jest'"