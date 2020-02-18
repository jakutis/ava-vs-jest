#!/usr/bin/env bash

RAMS="8 16 32 64 128 256 512 1024"
ENV="$1"
ROOT="$2"
SRC="$(pwd)"
if [ -n "$ROOT" ]
then
  ROOT="$(realpath "$ROOT")-$ENV"
else
  ROOT="$SRC-$ENV"
fi
mkdir -p $ROOT || exit

pip3 install csv2md --user
export PATH="$PATH:$HOME/.local/bin"

npm install
export PATH="$PATH:$(pwd)/node_modules/.bin"

function jest {
    (FATJEST_COUNT="$1" node --max_old_space_size=$2 ./node_modules/.bin/jest --env "$3" --silent jest-$3.spec.js 1>/dev/null 2>&1;echo $?)
}

function ava {
    (FATJEST_COUNT="$1" node --max_old_space_size=$2 ./node_modules/.bin/ava ava-$3.spec.js 1>/dev/null 2>&1;echo $?)
}

function runsome {
  MIN=1
  MAX=1000000
  MAXN=1
  while true
  do
    N=$((MIN + (MAX - MIN) / 2))
    echo $1 N=$N 1>&2
    START=$(date +%s)
    CODE=$($1 "$N" "$2" "$3")
    FINISH=$(date +%s)
    DURATION=$((FINISH - START))
    if [ "$CODE" == 0 ]
    then
      MAXN=$N
    fi
    if [ "$(((N - MIN) / 16))" = "0" -o "$(((MAX - N) / 16))" = "0" ]
    then
      break
    fi
    if [ "$CODE" == 0 ]
    then
      MIN=$N
    else
      MAX=$N
    fi
  done
  echo "$MAXN $DURATION"
}

rm "$ROOT/max-test-count."* "$ROOT/duration."* "$ROOT/memory-per-test."* "$ROOT/time-per-test."*

echo "RAM,ava,jest" > "$ROOT/max-test-count.csv"
echo "RAM,ava,jest" > "$ROOT/duration.csv"
echo "RAM,ava,jest" > "$ROOT/memory-per-test.csv"
echo "RAM,ava,jest" > "$ROOT/time-per-test.csv"
for R in $RAMS
do
  echo "R=$R ENV=$ENV"
  JEST=$(runsome "jest" "$R" "$ENV")
  JEST_N="${JEST%% *}"
  JEST_T="${JEST##* }"
  AVA=$(runsome "ava" "$R" "$ENV")
  AVA_N="${AVA%% *}"
  AVA_T="${AVA##* }"
  echo -n $AVA_N > "$ROOT/max-test-count-ava-$R"
  echo -n $JEST_N > "$ROOT/max-test-count-jest-$R"
  echo "$R,$AVA_N,$JEST_N" >> "$ROOT/max-test-count.csv"
  echo "$R,$AVA_T,$JEST_T" >> "$ROOT/duration.csv"
  echo "$R,$(echo $R/$AVA_N|bc -l),$(echo $R/$JEST_N|bc -l)" >> "$ROOT/memory-per-test.csv"
  echo "$R,$(echo $AVA_T/$AVA_N|bc -l),$(echo $JEST_T/$JEST_N|bc -l)" >> "$ROOT/time-per-test.csv"
done

csv2md "$ROOT/max-test-count.csv" > "$ROOT/max-test-count.md"
gnuplot -e "set datafile separator ',';set grid;set term png;set output '$ROOT/max-test-count.png';set ylabel 'maximum number of tests';set xlabel 'max-old-space-size, MB';plot '$ROOT/max-test-count.csv' using 1:2 with lines title 'ava', '$ROOT/max-test-count.csv' using 1:3 with lines title 'jest'"
csv2md "$ROOT/duration.csv" > "$ROOT/duration.md"
gnuplot -e "set datafile separator ',';set grid;set term png;set output '$ROOT/duration.png';set ylabel 'time, s';set xlabel 'max-old-space-size, MB';plot '$ROOT/duration.csv' using 1:2 with lines title 'ava', '$ROOT/duration.csv' using 1:3 with lines title 'jest'"
csv2md "$ROOT/memory-per-test.csv" > "$ROOT/memory-per-test.md"
gnuplot -e "set datafile separator ',';set grid;set term png;set output '$ROOT/memory-per-test.png';set ylabel 'memory, MB';set xlabel 'max-old-space-size, MB';plot '$ROOT/memory-per-test.csv' every ::4 using 1:2 with lines title 'ava', '$ROOT/memory-per-test.csv' every ::4 using 1:3 with lines title 'jest'"
csv2md "$ROOT/time-per-test.csv" > "$ROOT/time-per-test.md"
gnuplot -e "set datafile separator ',';set grid;set term png;set output '$ROOT/time-per-test.png';set ylabel 'time, s';set xlabel 'max-old-space-size, MB';plot '$ROOT/time-per-test.csv' every ::4 using 1:2 with lines title 'ava', '$ROOT/time-per-test.csv' every ::4 using 1:3 with lines title 'jest'"