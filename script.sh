#!/usr/bin/env bash

RAMS="128 256 512 1024"
NS="10000 20000 30000 40000 50000"
ROOT="$1"
if [ -n "$ROOT" ]
then
  ROOT="$(realpath "$ROOT")"
else
  ROOT="$(pwd)"
fi
mkdir -p $ROOT || exit
rm -f $ROOT/time $ROOT/max-ram $ROOT/failed

pip3 install psrecord matplotlib --user
export PATH="$PATH:$HOME/.local/bin"

npm install
export PATH="$PATH:$(pwd)/node_modules/.bin"

function jest {
    (FATJEST_COUNT="$1" node --max_old_space_size=$2 ./node_modules/.bin/jest --silent jest.spec.js 1>"$3.stdout" 2>&1;echo $? > "$3.code") &
    psrecord --include-children --plot "$3.pdf" --log "$3.log" 1>/dev/null 2>&1 $!
}

function ava {
    (FATJEST_COUNT="$1" node --max_old_space_size=$2 ./node_modules/.bin/ava ava.spec.js 1>"$3.stdout" 2>&1;echo $? > "$3.code") &
    psrecord --include-children --plot "$3.pdf" --log "$3.log" 1>/dev/null 2>&1 $!
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
      rm $BASE.pdf
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
  pdfjam $ROOT/result-jest-$R-*pdf --pagecommand "jest-$R" --nup 2x5 --outfile $ROOT/plot-jest-$R.pdf
  pdfjam $ROOT/result-ava-$R-*pdf --pagecommand "ava-$R" --nup 2x5 --outfile $ROOT/plot-ava-$R.pdf
  pdfjam $ROOT/plot-ava-$R.pdf $ROOT/plot-jest-$R.pdf --pagecommand "versus-$R" --nup 2x1 --outfile $ROOT/plot-versus-$R.pdf
done

pdfjam $ROOT/plot-versus-*.pdf --nup 1x1 --outfile $ROOT/plot-versus.pdf