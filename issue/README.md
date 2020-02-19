
We need need to evaluate options to migrate away from mocha.

We want to be efficient with our CI servers, developer machines and developer time.
Thus the first thing is the ability to run test files concurrently - only ava and jest does that.
Second is the actual performance of running the tests in our codebase, which already has many and will have more test files, many of which have very many generated tests.

So obviously best way to answer that is synthetic benchmarks with ava and jest side-by-side!
We run one test file with many empty tests, followed by many test files with one empty test.
You can find the scripts in [this repo](todo).
Below are the results, which conclude that jest is significantly inferior and our benchmarks end early.

Notes:
* the only features that jest bundles and we use and thus need to add to ava, are assertion library and JSDOM:
  * for assertion library, latest `chai` is used there
  * for JSDOM, latest `jsdom` is used there
* default `max-old-space-size` of Node.js is 512MB.
* the results are for Linux 4.19.0 kernel on `Intel(R) Core(TM) i7-7820HQ` CPU with `32GB` of RAM
* in the benchmarks ava test reporter is normal (names of all tests are printed), while jest is silenced (no test name output)
* to compile the images below, run `npm start` (it will take time)

Jump to:
- [Node.js environment test](#node)
- [JSDOM environment test](#jsdom)

<a name="node"/></a>

# node

ava test:
```javascript
const test = require('ava');
const { expect } = require('chai')

for (var i = 1; i <= Number(process.env.FATJEST_COUNT); i++) {
  test('product #' + i, t => {
    expect('hi').to.equal('hi')
    t.pass()
  })
}

```

jest test:
```javascript
describe('product', () => {
  for (var i = 1; i <= Number(process.env.FATJEST_COUNT); i++) {
    test('works #' + i, () => {
      expect('hi').toBe('hi')
    })
  }
})

```

## many files with one test

Both ava and jest are set to run 4 files concurrently.

### max memory used

![TODO](results-node/memory.png)
| N    | ava     | jest    |
| ---- | ------- | ------- |
| 1    | 96.020  | 98.930  |
| 2    | 138.039 | 267.898 |
| 4    | 225.836 | 362.121 |
| 8    | 216.336 | 427.332 |
| 16   | 228.043 | 466.863 |
| 32   | 226.016 | 505.980 |
| 64   | 230.562 | 580.746 |
| 128  | 235.312 | 673.922 |
| 256  | 250.434 | 680.578 |
| 512  | 255.836 | 710.992 |
| 1024 | 266.977 | 941.172 |


### duration

![TODO](results-node/multifile-duration.png)
| N    | ava | jest |
| ---- | --- | ---- |
| 1    | 1   | 1    |
| 2    | 0   | 2    |
| 4    | 1   | 2    |
| 8    | 1   | 2    |
| 16   | 2   | 2    |
| 32   | 3   | 2    |
| 64   | 4   | 3    |
| 128  | 8   | 5    |
| 256  | 14  | 10   |
| 512  | 29  | 18   |
| 1024 | 60  | 34   |


### max mean memory used per file

![TODO](results-node/memory-per-file.png)
| N    | ava                     | jest                     |
| ---- | ----------------------- | ------------------------ |
| 1    | 96.02000000000000000000 | 98.93000000000000000000  |
| 2    | 69.01950000000000000000 | 133.94900000000000000000 |
| 4    | 56.45900000000000000000 | 90.53025000000000000000  |
| 8    | 27.04200000000000000000 | 53.41650000000000000000  |
| 16   | 14.25268750000000000000 | 29.17893750000000000000  |
| 32   | 7.06300000000000000000  | 15.81187500000000000000  |
| 64   | 3.60253125000000000000  | 9.07415625000000000000   |
| 128  | 1.83837500000000000000  | 5.26501562500000000000   |
| 256  | .97825781250000000000   | 2.65850781250000000000   |
| 512  | .49967968750000000000   | 1.38865625000000000000   |
| 1024 | .26071972656250000000   | .91911328125000000000    |


### mean duration per file

![TODO](results-node/time-per-file.png)
| N    | ava                    | jest                   |
| ---- | ---------------------- | ---------------------- |
| 1    | 1.00000000000000000000 | 1.00000000000000000000 |
| 2    | 0                      | 1.00000000000000000000 |
| 4    | .25000000000000000000  | .50000000000000000000  |
| 8    | .12500000000000000000  | .25000000000000000000  |
| 16   | .12500000000000000000  | .12500000000000000000  |
| 32   | .09375000000000000000  | .06250000000000000000  |
| 64   | .06250000000000000000  | .04687500000000000000  |
| 128  | .06250000000000000000  | .03906250000000000000  |
| 256  | .05468750000000000000  | .03906250000000000000  |
| 512  | .05664062500000000000  | .03515625000000000000  |
| 1024 | .05859375000000000000  | .03320312500000000000  |


## one file with many tests

### search for maximum number of tests

#### maximum number of tests per max-old-space-size

![TODO](results-node/max-test-count.png)
| RAM  | ava    | jest   |
| ---- | ------ | ------ |
| 8    | 489    | 1      |
| 16   | 3158   | 31     |
| 32   | 6805   | 1571   |
| 64   | 15777  | 4730   |
| 128  | 32531  | 12191  |
| 256  | 66406  | 26945  |
| 512  | 136855 | 56624  |
| 1024 | 226546 | 115340 |


#### time to run maximum number of tests

![TODO](results-node/duration.png)
| RAM  | ava | jest |
| ---- | --- | ---- |
| 8    | 1   | 0    |
| 16   | 1   | 1    |
| 32   | 1   | 2    |
| 64   | 1   | 4    |
| 128  | 2   | 9    |
| 256  | 4   | 32   |
| 512  | 13  | 191  |
| 1024 | 20  | 641  |


#### memory per single test, >=64MB

![TODO](results-node/memory-per-test.png)
| RAM  | ava                   | jest                   |
| ---- | --------------------- | ---------------------- |
| 8    | .01635991820040899795 | 8.00000000000000000000 |
| 16   | .00506649778340721975 | .51612903225806451612  |
| 32   | .00470242468772961058 | .02036919159770846594  |
| 64   | .00405653799835203143 | .01353065539112050739  |
| 128  | .00393470843195721004 | .01049954884751045853  |
| 256  | .00385507333674667951 | .00950083503432918908  |
| 512  | .00374118592671075225 | .00904210228878214184  |
| 1024 | .00452005332250403891 | .00887809953181897000  |


#### time per single test, >=64MB

![TODO](results-node/time-per-test.png)
| RAM  | ava                   | jest                  |
| ---- | --------------------- | --------------------- |
| 8    | .00204498977505112474 | 0                     |
| 16   | .00031665611146295123 | .03225806451612903225 |
| 32   | .00014695077149155033 | .00127307447485677912 |
| 64   | .00006338340622425049 | .00084566596194503171 |
| 128  | .00006147981924933140 | .00073824952834057911 |
| 256  | .00006023552088666686 | .00118760437929114863 |
| 512  | .00009499104892039019 | .00337312800226052557 |
| 1024 | .00008828229145515701 | .00555748222646089821 |


### memory usage plot

Ava on the left, Jest on the right.

#### 10000

![TODO](results-node/plot-sidebyside-512-10000.png)

#### 25000

![TODO](results-node/plot-sidebyside-512-25000.png)

#### 50000

![TODO](results-node/plot-sidebyside-512-50000.png)

#### 56624 (max for jest)

![TODO](results-node/plot-sidebyside-512-56624.png)

#### 136855 (max for ava)

![TODO](results-node/plot-sidebyside-512-136855.png)

### time to run

![TODO](results-node/duration-512.png)
| tests  | ava | jest |
| ------ | --- | ---- |
| 10000  | 2   | 7    |
| 25000  | 3   | 33   |
| 50000  | 5   | 137  |
| 56624  | -   | 217  |
| 136855 | 16  | -    |


<a name="jsdom"/></a>

# jsdom

ava test:
```javascript
const test = require('ava')
const { expect } = require('chai')
const React = require('react')
const { render, findDOMNode } = require('react-dom')
const { JSDOM } = require('jsdom')
global.window = (new JSDOM('<!doctype html><html><body></body></html>', {
  url: 'https://example.org/',
  referrer: 'https://example.com/',
  contentType: 'text/html',
  includeNodeLocations: true,
  storageQuota: 10000000
})).window
global.document = global.window.document

for (const key in global.window) {
  if (global.window.hasOwnProperty(key) && !(key in global)) {
    global[key] = global.window[key]
  }
}

for (var i = 1; i <= Number(process.env.FATJEST_COUNT); i++) {
  test('product #' + i, t => {
    const container = document.createElement('div')
    document.body.appendChild(container)
    const element = React.createElement('p', {}, 'hi')
    const component = render(element, container)
    const node = findDOMNode(component)
    expect(node.innerHTML).to.equal('hi')
    document.body.removeChild(container)
    t.pass()
  })
}

```

jest test:
```javascript
const React = require('react')
const { render, findDOMNode } = require('react-dom')

describe('product', () => {
  for (var i = 1; i <= Number(process.env.FATJEST_COUNT); i++) {
    test('works #' + i, () => {
      const container = document.createElement('div')
      document.body.appendChild(container)
      const element = React.createElement('p', {}, 'hi')
      const component = render(element, container)
      const node = findDOMNode(component)
      expect(node.innerHTML).toBe('hi')
      document.body.removeChild(container)
    })
  }
})

```

## many files with one test

Both ava and jest are set to run 4 files concurrently.

### max memory used

![TODO](results-jsdom/memory.png)
| N    | ava     | jest     |
| ---- | ------- | -------- |
| 1    | 151.527 | 134.332  |
| 2    | 228.422 | 382.320  |
| 4    | 378.695 | 549.668  |
| 8    | 366.453 | 568.043  |
| 16   | 378.098 | 590.301  |
| 32   | 381.316 | 640.617  |
| 64   | 374.355 | 768.734  |
| 128  | 393.074 | 1006.043 |
| 256  | 390.672 | 1012.000 |
| 512  | 389.676 | 1062.160 |
| 1024 | 406.750 | 1357.398 |


### duration

![TODO](results-jsdom/multifile-duration.png)
| N    | ava | jest |
| ---- | --- | ---- |
| 1    | 2   | 2    |
| 2    | 1   | 2    |
| 4    | 2   | 3    |
| 8    | 2   | 3    |
| 16   | 4   | 4    |
| 32   | 8   | 3    |
| 64   | 14  | 4    |
| 128  | 27  | 6    |
| 256  | 55  | 8    |
| 512  | 107 | 13   |
| 1024 | 230 | 29   |


### max mean memory used per file

![TODO](results-jsdom/memory-per-file.png)
| N    | ava                      | jest                     |
| ---- | ------------------------ | ------------------------ |
| 1    | 151.52700000000000000000 | 134.33200000000000000000 |
| 2    | 114.21100000000000000000 | 191.16000000000000000000 |
| 4    | 94.67375000000000000000  | 137.41700000000000000000 |
| 8    | 45.80662500000000000000  | 71.00537500000000000000  |
| 16   | 23.63112500000000000000  | 36.89381250000000000000  |
| 32   | 11.91612500000000000000  | 20.01928125000000000000  |
| 64   | 5.84929687500000000000   | 12.01146875000000000000  |
| 128  | 3.07089062500000000000   | 7.85971093750000000000   |
| 256  | 1.52606250000000000000   | 3.95312500000000000000   |
| 512  | .76108593750000000000    | 2.07453125000000000000   |
| 1024 | .39721679687500000000    | 1.32558398437500000000   |


### mean duration per file

![TODO](results-jsdom/time-per-file.png)
| N    | ava                    | jest                   |
| ---- | ---------------------- | ---------------------- |
| 1    | 2.00000000000000000000 | 2.00000000000000000000 |
| 2    | .50000000000000000000  | 1.00000000000000000000 |
| 4    | .50000000000000000000  | .75000000000000000000  |
| 8    | .25000000000000000000  | .37500000000000000000  |
| 16   | .25000000000000000000  | .25000000000000000000  |
| 32   | .25000000000000000000  | .09375000000000000000  |
| 64   | .21875000000000000000  | .06250000000000000000  |
| 128  | .21093750000000000000  | .04687500000000000000  |
| 256  | .21484375000000000000  | .03125000000000000000  |
| 512  | .20898437500000000000  | .02539062500000000000  |
| 1024 | .22460937500000000000  | .02832031250000000000  |


## one file with many tests

### search for maximum number of tests

#### maximum number of tests per max-old-space-size

![TODO](results-jsdom/max-test-count.png)
| RAM  | ava    | jest   |
| ---- | ------ | ------ |
| 8    | 1      | 1      |
| 16   | 1      | 1      |
| 32   | 1954   | 1      |
| 64   | 10254  | 2442   |
| 128  | 28319  | 8545   |
| 256  | 58348  | 21484  |
| 512  | 74706  | 47119  |
| 1024 | 100341 | 101073 |


#### time to run maximum number of tests

![TODO](results-jsdom/duration.png)
| RAM  | ava | jest |
| ---- | --- | ---- |
| 8    | 0   | 1    |
| 16   | 1   | 1    |
| 32   | 3   | 2    |
| 64   | 6   | 7    |
| 128  | 7   | 16   |
| 256  | 15  | 58   |
| 512  | 11  | 207  |
| 1024 | 15  | 585  |


#### memory per single test, >=64MB

![TODO](results-jsdom/memory-per-test.png)
| RAM  | ava                     | jest                    |
| ---- | ----------------------- | ----------------------- |
| 8    | 8.00000000000000000000  | 8.00000000000000000000  |
| 16   | 16.00000000000000000000 | 16.00000000000000000000 |
| 32   | .01637666325486182190   | 32.00000000000000000000 |
| 64   | .00624146674468500097   | .02620802620802620802   |
| 128  | .00451993361347505208   | .01497952018724400234   |
| 256  | .00438746829368615890   | .01191584434928318748   |
| 512  | .00685353251412202500   | .01086610496827182240   |
| 1024 | .01020520026708922574   | .01013129124494177475   |


#### time per single test, >=64MB

![TODO](results-jsdom/time-per-test.png)
| RAM  | ava                    | jest                   |
| ---- | ---------------------- | ---------------------- |
| 8    | 0                      | 1.00000000000000000000 |
| 16   | 1.00000000000000000000 | 1.00000000000000000000 |
| 32   | .00153531218014329580  | 2.00000000000000000000 |
| 64   | .00058513750731421884  | .00286650286650286650  |
| 128  | .00024718386948691691  | .00187244002340550029  |
| 256  | .00025707822033317337  | .00269968348538447216  |
| 512  | .00014724386260809038  | .00439313228209427194  |
| 1024 | .00014949023828743983  | .00578789587723724436  |


### memory usage plot

Ava on the left, Jest on the right.

#### 10000

![TODO](results-jsdom/plot-sidebyside-512-10000.png)

#### 25000

![TODO](results-jsdom/plot-sidebyside-512-25000.png)

#### 50000

![TODO](results-jsdom/plot-sidebyside-512-50000.png)

#### 47119 (max for jest)

![TODO](results-jsdom/plot-sidebyside-512-47119.png)

#### 74706 (max for ava)

![TODO](results-jsdom/plot-sidebyside-512-74706.png)

### time to run

![TODO](results-jsdom/duration-512.png)
| tests | ava | jest |
| ----- | --- | ---- |
| 10000 | 3   | 12   |
| 25000 | 5   | 54   |
| 50000 | 9   | -    |
| 47119 | -   | 160  |
| 74706 | 13  | -    |


