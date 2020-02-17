#!/usr/bin/env bash

RAMS="512"
NS="10000 25000 50000"
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
NS="$NS $(cat "$ROOT/max-test-count-jest-512") $(cat "$ROOT/max-test-count-ava-512")"
rm -f $ROOT/failed $ROOT/time $ROOT/max-ram

pip3 install psrecord matplotlib csv2md --user
export PATH="$PATH:$HOME/.local/bin"

npm install
export PATH="$PATH:$(pwd)/node_modules/.bin"

function jest {
    (FATJEST_COUNT="$1" node --max_old_space_size=$2 ./node_modules/.bin/jest --env "$4" --silent "jest-$4.spec.js" 1>"$3.stdout" 2>&1;echo $? > "$3.code") &
    psrecord --include-children --plot "$3.png" --log "$3.log" 1>/dev/null 2>&1 $!
}

function ava {
    (FATJEST_COUNT="$1" node --max_old_space_size=$2 ./node_modules/.bin/ava "ava-$4.spec.js" 1>"$3.stdout" 2>&1;echo $? > "$3.code") &
    psrecord --include-children --plot "$3.png" --log "$3.log" 1>/dev/null 2>&1 $!
}

function runsome {
    CMD="$1"
    N="$2"
    RAM="$3"
    ENV="$4"
    BASE="$ROOT/result-$CMD-$RAM-$N"

    echo "# N=$N R=$RAM"
    I=0
    rm -f "$BASE"*
    while [ "$(cat "$BASE.code")" != "0" -a "$I" != "5" ]
    do
      rm -f "$BASE"*
      date +%s > "$BASE.start"
      $CMD "$N" "$RAM" "$BASE" "$ENV"
      date +%s > "$BASE.finish"
      I=$((I + 1))
      echo \#$I try done
    done
    TIME=$(($(cat "$BASE.finish") - $(cat "$BASE.start")))
    echo "$BASE $TIME" >> $ROOT/time
    MAXRAM=$(cat "$BASE.log" | sed 's/\s\s*/ /g' |tail -n +2|cut -f 4 -d ' '|sort -n|tail -n 1)
    echo "$BASE $MAXRAM" >> $ROOT/max-ram
    echo "code=$(cat "$BASE.code")"
    if [ "$(cat "$BASE.code")" != "0" ]
    then
      echo $BASE >> $ROOT/failed
    fi
}

for R in $RAMS
do
  for N in $NS
  do
    runsome ava $N $R $ENV
  done
done

for R in $RAMS
do
  for N in $NS
  do
    runsome jest $N $R $ENV
  done
done

for R in $RAMS
do
  rm -f "$ROOT/duration-$R."*
  echo "tests,ava,jest" > "$ROOT/duration-$R.csv"
  for N in $NS
  do
    convert +append $ROOT/result-ava-$R-$N.png $ROOT/result-jest-$R-$N.png $ROOT/plot-sidebyside-$R-$N.png
    if [ "$(cat "$ROOT/result-jest-$R-$N.code")" = "0" ]
    then
      JEST_F="$(cat "$ROOT/result-jest-$R-$N.finish")"
      JEST_S="$(cat "$ROOT/result-jest-$R-$N.start")"
      JEST=$((JEST_F - JEST_S))
    else
      JEST="-"
    fi
    if [ "$(cat "$ROOT/result-ava-$R-$N.code")" = "0" ]
    then
      AVA_F="$(cat "$ROOT/result-ava-$R-$N.finish")"
      AVA_S="$(cat "$ROOT/result-ava-$R-$N.start")"
      AVA=$((AVA_F - AVA_S))
    else
      AVA="-"
    fi
    echo "$N,$AVA,$JEST" >> "$ROOT/duration-$R.csv"
  done
  csv2md "$ROOT/duration-$R.csv" > "$ROOT/duration-$R.md"
  gnuplot -e "set datafile separator ',';set grid;set term png;set output '$ROOT/duration-$R.png';set ylabel 'time, s';set xlabel 'number of tests';plot '$ROOT/duration-$R.csv' using 1:2 with lines title 'ava', '$ROOT/duration-$R.csv' using 1:3 with lines title 'jest'"
done