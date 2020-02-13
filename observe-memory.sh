#!/usr/bin/env bash

RAMS="512"
NS="10000 25000 50000 52735 135555"
ROOT="$1"
if [ -n "$ROOT" ]
then
  ROOT="$(realpath "$ROOT")"
else
  ROOT="$(pwd)"
fi
mkdir -p $ROOT || exit
rm -f $ROOT/time $ROOT/max-ram $ROOT/failed

pip3 install psrecord matplotlib csv2md --user
export PATH="$PATH:$HOME/.local/bin"

npm install
export PATH="$PATH:$(pwd)/node_modules/.bin"

function jest {
    (FATJEST_COUNT="$1" node --max_old_space_size=$2 ./node_modules/.bin/jest --silent jest.spec.js 1>"$3.stdout" 2>&1;echo $? > "$3.code") &
    psrecord --include-children --plot "$3.png" --log "$3.log" 1>/dev/null 2>&1 $!
}

function ava {
    (FATJEST_COUNT="$1" node --max_old_space_size=$2 ./node_modules/.bin/ava ava.spec.js 1>"$3.stdout" 2>&1;echo $? > "$3.code") &
    psrecord --include-children --plot "$3.png" --log "$3.log" 1>/dev/null 2>&1 $!
}

function runsome {
    CMD="$1"
    N="$2"
    RAM="$3"
    BASE="$ROOT/result-$CMD-$RAM-$N"

    echo "# N=$N R=$RAM"
    date +%s > "$BASE.start"
    $CMD "$N" "$RAM" "$BASE"
    date +%s > "$BASE.finish"
    TIME=$(($(cat "$BASE.finish") - $(cat "$BASE.start")))
    echo "$BASE $TIME" >> $ROOT/time
    MAXRAM=$(cat "$BASE.log" | sed 's/\s\s*/ /g' |tail -n +2|cut -f 4 -d ' '|sort -n|tail -n 1)
    echo "$BASE $MAXRAM" >> $ROOT/max-ram
    if [ "$(cat "$BASE.code")" != "0" ]
    then
      rm $BASE.png
      echo $BASE >> $ROOT/failed
    fi
}

echo ========================================================================
echo AVA
echo ========================================================================
echo

for R in $RAMS
do
  for N in $NS
  do
    runsome ava $N $R
  done
done

echo ========================================================================
echo JEST
echo ========================================================================
echo

for R in $RAMS
do
  for N in $NS
  do
    runsome jest $N $R
  done
done

for R in $RAMS
do
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