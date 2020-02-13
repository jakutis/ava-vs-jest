We need need to evaluate options to migrate away from mocha.

We want to be efficient with our CI servers, developer machines and developer time.
Thus the first thing is the ability to run test files concurrently - only ava and jest does that.
Second is the actual performance of running the tests in our codebase, which already has many and will have more test files, many of which have very many generated tests.

So obviously best way to answer that is synthetic benchmarks with ava and jest side-by-side!
First basic step is to run one test file with many empty tests.
You can find the scripts in [this repo](todo).
Below are the results, which conclude that jest is significantly inferior and our benchmarks end early.

Note: default `max-old-space-size` of Node.js is 512MB.

# search for maximum number of tests

## maximum number of tests per max-old-space-size

![TODO](max-test-count.png)
| RAM  | ava    | jest   |
| ---- | ------ | ------ |
| 8    | 1100   | 2      |
| 16   | 3878   | 2      |
| 32   | 8206   | 2      |
| 64   | 15518  | 3466   |
| 128  | 32177  | 10283  |
| 256  | 64798  | 24427  |
| 512  | 135555 | 52735  |
| 1024 | 243167 | 110287 |

## time to run maximum number of tests

![TODO](duration.png)
| RAM  | ava | jest |
| ---- | --- | ---- |
| 8    | 1   | 0    |
| 16   | 1   | 0    |
| 32   | 2   | 1    |
| 64   | 1   | 3    |
| 128  | 4   | 8    |
| 256  | 6   | 26   |
| 512  | 12  | 119  |
| 1024 | 11  | 513  |

## memory per single test, >=64MB

![TODO](memory-per-test.png)
| RAM  | ava                   | jest                    |
| ---- | --------------------- | ----------------------- |
| 8    | .00727272727272727272 | 4.00000000000000000000  |
| 16   | .00412583806085611139 | 8.00000000000000000000  |
| 32   | .00389958566902266634 | 16.00000000000000000000 |
| 64   | .00412424281479572109 | .01846508944027697634   |
| 128  | .00397799670572147807 | .01244772926188855392   |
| 256  | .00395073922034630698 | .01048020632906210341   |
| 512  | .00377706466010106598 | .00970892196833222717   |
| 1024 | .00421109772296405351 | .00928486585000952061   |

## time per single test, >=64MB

![TODO](time-per-test.png)
| RAM  | ava                   | jest                  |
| ---- | --------------------- | --------------------- |
| 8    | .00090909090909090909 | 0                     |
| 16   | .00025786487880350696 | 0                     |
| 32   | .00024372410431391664 | .5                    |
| 64   | .00006444129398118314 | .00086555106751298326 |
| 128  | .00012431239705379618 | .00077798307886803462 |
| 256  | .00009259545047686656 | .00106439595529536987 |
| 512  | .00008852495297111873 | .00225656584810846686 |
| 1024 | .00004523640132090291 | .00465150017681141022 |

# memory usage plot

Ava on the left, Jest on the right.

## 10000

![TODO](plot-sidebyside-512-10000.png)

## 25000

![TODO](plot-sidebyside-512-25000.png)

## 50000

![TODO](plot-sidebyside-512-50000.png)

## 52735 (max for jest)

![TODO](plot-sidebyside-512-52735.png)

## 135555 (max for ava)

![TODO](plot-sidebyside-512-135555.png)

# time to run

![TODO](duration-512.png)
| tests  | ava | jest |
| ------ | --- | ---- |
| 10000  | 2   | 10   |
| 25000  | 4   | 66   |
| 50000  | 6   | 229  |
| 52735  | 7   | 238  |
| 135555 | 17  | -    |
