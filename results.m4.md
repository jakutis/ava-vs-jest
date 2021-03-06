<a name="__env__"/></a>

# __env__

AVA test:
```javascript
include(ava-__env__.spec.js)
```

Jest test:
```javascript
include(jest-__env__.spec.js)
```

## many files with one test

Both AVA and Jest are set to run 4 files concurrently.

### max memory used

![TODO](results-__env__/memory.png)
include(issue/results-__env__/memory.md)

### duration

![TODO](results-__env__/multifile-duration.png)
include(issue/results-__env__/multifile-duration.md)

### max mean memory used per file

![TODO](results-__env__/memory-per-file.png)
include(issue/results-__env__/memory-per-file.md)

### mean duration per file

![TODO](results-__env__/time-per-file.png)
include(issue/results-__env__/time-per-file.md)

## one file with many tests

### search for maximum number of tests

#### maximum number of tests per max-old-space-size

![TODO](results-__env__/max-test-count.png)
include(issue/results-__env__/max-test-count.md)

#### time to run maximum number of tests

![TODO](results-__env__/duration.png)
include(issue/results-__env__/duration.md)

#### memory per single test, >=64MB

![TODO](results-__env__/memory-per-test.png)
include(issue/results-__env__/memory-per-test.md)

#### time per single test, >=64MB

![TODO](results-__env__/time-per-test.png)
include(issue/results-__env__/time-per-test.md)

### memory usage plot

When max-old-space-size is 512MB.
AVA on the left, Jest on the right. 

#### 10000

![TODO](results-__env__/plot-sidebyside-512-10000.png)

#### 25000

![TODO](results-__env__/plot-sidebyside-512-25000.png)

#### 50000

![TODO](results-__env__/plot-sidebyside-512-50000.png)

#### include(issue/results-__env__/max-test-count-jest-512) (max for Jest)

![TODO](results-__env__/plot-sidebyside-512-include(issue/results-__env__/max-test-count-jest-512).png)

#### include(issue/results-__env__/max-test-count-ava-512) (max for AVA)

![TODO](results-__env__/plot-sidebyside-512-include(issue/results-__env__/max-test-count-ava-512).png)

### time to run

When max-old-space-size is 512MB.

![TODO](results-__env__/duration-512.png)
include(issue/results-__env__/duration-512.md)
