#!/usr/bin/env bash

MEMORIES="512"
NS="10000 25000 50000"

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

rm -f $ROOT/failed $ROOT/time $ROOT/max-ram

pip3 install psrecord matplotlib csv2md --user
export PATH="$PATH:$(python3 -m site --user-base)/bin"

npm install
export PATH="$PATH:$(pwd)/node_modules/.bin"

function jest {
    (FATJEST_COUNT="$1" node --max_old_space_size=$2 ./node_modules/.bin/jest --env "$4" --silent "jest-$4.spec.js" 1>"$3.stdout" 2>&1;echo $? > "$3.code") &
    psrecord --include-children --plot "$3.png" --log "$3.log" 1>/dev/null 2>&1 $!
}

function ava {
    (FATJEST_COUNT="$1" node --max_old_space_size=$2 ./node_modules/.bin/jest --testRunner='jest-circus/runner' --env "$4" --silent "jest-$4.spec.js" 1>"$3.stdout" 2>&1;echo $? > "$3.code") &
    psrecord --include-children --plot "$3.png" --log "$3.log" 1>/dev/null 2>&1 $!
}

function runsome {
    CMD="$1"
    N="$2"
    MEMORY="$3"
    ENV="$4"
    ALLOWFAILURE="$5"
    BASE="$ROOT/result-$CMD-$MEMORY-$N"

    echo "# $CMD N=$N R=$MEMORY"
    I=0
    rm -f "$BASE"*
    while [ "$(cat "$BASE.code")" != "0" ]
    do
      echo try \#$((I + 1))
      rm -f "$BASE"*
      date +%s > "$BASE.start"
      $CMD "$N" "$MEMORY" "$BASE" "$ENV"
      date +%s > "$BASE.finish"
      I=$((I + 1))
      if [ "$ALLOWFAILURE" = "yes" -a "$I" == "5" ]
      then
        break
      fi
    done
    TIME=$(($(cat "$BASE.finish") - $(cat "$BASE.start")))
    echo "$BASE $TIME" >> $ROOT/time
    MAXMEMORY=$(cat "$BASE.log" | sed 's/\s\s*/ /g' |tail -n +2|cut -f 4 -d ' '|sort -n|tail -n 1)
    echo "$BASE $MAXMEMORY" >> $ROOT/max-ram
    echo "code=$(cat "$BASE.code")"
    if [ "$(cat "$BASE.code")" != "0" ]
    then
      echo $BASE >> $ROOT/failed
    fi
}

for R in $MEMORIES
do
  for N in $NS
  do
    runsome ava $N $R $ENV yes
  done
done
runsome ava $(cat "$ROOT/max-test-count-ava-512") 512 $ENV no

for R in $MEMORIES
do
  for N in $NS
  do
    runsome jest $N $R $ENV yes
  done
done
runsome jest $(cat "$ROOT/max-test-count-jest-512") 512 $ENV no

for R in $MEMORIES
do
  rm -f "$ROOT/duration-$R."*
  echo "tests,AVA,Jest" > "$ROOT/duration-$R.csv"
  for N in $NS $(cat "$ROOT/max-test-count-jest-512") $(cat "$ROOT/max-test-count-ava-512")
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
  gnuplot -e "set datafile separator ',';set grid;set term png;set output '$ROOT/duration-$R.png';set ylabel 'time, s';set xlabel 'number of tests';plot '$ROOT/duration-$R.csv' using 1:2 with lines title 'AVA', '$ROOT/duration-$R.csv' using 1:3 with lines title 'Jest'"
done