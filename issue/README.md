We need need to evaluate options to migrate away from mocha.

We want to be efficient with our CI servers, developer machines and developer time.
Thus the first thing is the ability to run test files concurrently - only ava and jest does that.
Second is the actual performance of running the tests in our codebase, which already has many and will have more test files, many of which have very many generated tests.

So obviously best way to answer that is synthetic benchmarks with ava and jest side-by-side!
First basic step is to run one test file with many empty tests.
You can find the scripts in [this repo](todo).
Below are the results, which conclude that jest is significantly inferior and our benchmarks end early.

Notes:
* default `max-old-space-size` of Node.js is 512MB.
* in the benchmarks ava test reporter is normal (names of all tests are printed), while jest is silenced (no output)
* to compile the images below, run `npm start` (it will take time)

# many files with one test

## max memory used

![TODO](memory.png)
| N    | ava     | jest     |
| ---- | ------- | -------- |
| 1    | 99.215  | 119.699  |
| 2    | 138.598 | 423.500  |
| 4    | 215.480 | 579.242  |
| 8    | 340.074 | 798.066  |
| 16   | 364.109 | 812.184  |
| 32   | 351.168 | 858.465  |
| 64   | 363.418 | 946.598  |
| 128  | 359.648 | 1145.953 |
| 256  | 383.906 | 1479.441 |
| 512  | 396.094 | 1723.340 |
| 1024 | 408.047 | 2214.625 |

## duration

![TODO](multifile-duration.png)
| N    | ava | jest |
| ---- | --- | ---- |
| 1    | 1   | 2    |
| 2    | 1   | 3    |
| 4    | 1   | 3    |
| 8    | 2   | 3    |
| 16   | 2   | 4    |
| 32   | 2   | 4    |
| 64   | 5   | 4    |
| 128  | 8   | 6    |
| 256  | 14  | 8    |
| 512  | 28  | 14   |
| 1024 | 59  | 23   |

## max mean memory used per file

![TODO](memory-per-file.png)
| N    | ava                     | jest                     |
| ---- | ----------------------- | ------------------------ |
| 1    | 99.21500000000000000000 | 119.69900000000000000000 |
| 2    | 69.29900000000000000000 | 211.75000000000000000000 |
| 4    | 53.87000000000000000000 | 144.81050000000000000000 |
| 8    | 42.50925000000000000000 | 99.75825000000000000000  |
| 16   | 22.75681250000000000000 | 50.76150000000000000000  |
| 32   | 10.97400000000000000000 | 26.82703125000000000000  |
| 64   | 5.67840625000000000000  | 14.79059375000000000000  |
| 128  | 2.80975000000000000000  | 8.95275781250000000000   |
| 256  | 1.49963281250000000000  | 5.77906640625000000000   |
| 512  | .77362109375000000000   | 3.36589843750000000000   |
| 1024 | .39848339843750000000   | 2.16271972656250000000   |

## mean duration per file

![TODO](time-per-file.png)
| N    | ava                    | jest                   |
| ---- | ---------------------- | ---------------------- |
| 1    | 1.00000000000000000000 | 2.00000000000000000000 |
| 2    | .50000000000000000000  | 1.50000000000000000000 |
| 4    | .25000000000000000000  | .75000000000000000000  |
| 8    | .25000000000000000000  | .37500000000000000000  |
| 16   | .12500000000000000000  | .25000000000000000000  |
| 32   | .06250000000000000000  | .12500000000000000000  |
| 64   | .07812500000000000000  | .06250000000000000000  |
| 128  | .06250000000000000000  | .04687500000000000000  |
| 256  | .05468750000000000000  | .03125000000000000000  |
| 512  | .05468750000000000000  | .02734375000000000000  |
| 1024 | .05761718750000000000  | .02246093750000000000  |

# one file with many tests

## search for maximum number of tests

### maximum number of tests per max-old-space-size

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

### time to run maximum number of tests

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

### memory per single test, >=64MB

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

### time per single test, >=64MB

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

## memory usage plot

Ava on the left, Jest on the right.

### 10000

![TODO](plot-sidebyside-512-10000.png)

### 25000

![TODO](plot-sidebyside-512-25000.png)

### 50000

![TODO](plot-sidebyside-512-50000.png)

### 52735 (max for jest)

![TODO](plot-sidebyside-512-52735.png)

### 135555 (max for ava)

![TODO](plot-sidebyside-512-135555.png)

## time to run

![TODO](duration-512.png)
| tests  | ava | jest |
| ------ | --- | ---- |
| 10000  | 2   | 10   |
| 25000  | 4   | 66   |
| 50000  | 6   | 229  |
| 52735  | 7   | 238  |
| 135555 | 17  | -    |
