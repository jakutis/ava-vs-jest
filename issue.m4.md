changequote(`{{', `}}')dnl
changecom(`%%`)
We need need to evaluate options to migrate away from mocha.

We want to be efficient with our CI servers, developer machines and developer time.
Thus the first thing is the ability to run test files concurrently - only AVA and Jest does that.
Second is the actual performance of running the tests in our codebase, which already has many and will have more test files, many of which have very many generated tests.

So obviously best way to answer that is synthetic benchmarks with AVA and Jest side-by-side!
We run one test file with many empty tests, followed by many test files with one empty test.
You can find the scripts in [this repo](https://github.com/jakutis/ava-vs-jest).

Notes:
* the only features that Jest bundles and we use and thus need to add to AVA, are assertion library and JSDOM:
  * for assertion library, latest `chai` is used there
  * for JSDOM, latest `jsdom` is used there
* Node.js memory control is performed via the `max-old-space-size` argument, default is 512MB
* the results are for Linux 4.19.0 kernel on `Intel(R) Core(TM) i7-7820HQ` CPU with `32GB` of RAM
* degree of parallelism for both AVA and Jest are set to 4
* in the benchmarks AVA test reporter is normal (names of all tests are printed), while Jest is silenced (no test name output)
* to compile the images below, run `npm start` (it will take time)


Jump to:
- [Node.js environment test](#node)
- [JSDOM environment test](#jsdom)


Below are the results, which conclude:
- Jest is significantly inferior everywhere except in running many (more than 100) test files in parallel
- node+many files one test
  - Jest uses 3 times more memory (673MB vs. 235MB for 128 test files) ([see graph](#max-memory-used))
  - Jest is 1.5 times faster (5s vs. 8s for 128 test files, 10s vs. 14s for 256 test files) ([see graph](#duration))
- node+one file many tests
  - Jest uses 2 times more memory (can run 56624 tests vs. 136855 for 512MB of memory) ([see graph](#maximum-number-of-tests-per-max-old-space-size))
  - Jest is slower ([see graph](#time-to-run))
    - with 512MB of memory: 4 times slower for 10000 tests, 11 times slower for 25000 tests, 27 times slower for 50000 tests
    - aggressively spends time to run garbage collector ([see graphs](#memory-usage-plot))
    - [see graph](#time-to-run-maximum-number-of-tests) for maximum number of tests
      - with 128MB memory: 4 times slower for max tests
      - with 256MB memory: 8 times slower for max tests
      - with 512MB memory: 13 times slower for max tests 
- jsdom+many files one test
  - Jest uses 3 times more memory (1006MB vs. 393MB for 128 test files) ([see graph](#max-memory-used-1))
  - Jest is 6 times faster (6s vs. 27s for 128 test files, 8s vs. 55s for 256 test files) ([see graph](#duration-1))
- jsdom+one file many tests
  - Jest uses 2 times more memory (can run 47119 tests vs. 74706 for 512MB of memory) ([see graph](#maximum-number-of-tests-per-max-old-space-size-1)) TODOrecheck
  - Jest is slower ([see graph](#time-to-run-1))
    - with 512MB of memory: 4 times slower for 10000 tests, 11 times slower for 25000 tests
    - aggressively spends time to run garbage collector ([see graphs](#memory-usage-plot-1))
    - [see graph](#time-to-run-maximum-number-of-tests-1) for maximum number of tests
      - with 128MB memory: 2 times slower
      - with 256MB memory: 4 times slower
      - with 512MB memory: 19 times slower 

define({{__env__}}, {{node}})dnl
include({{results.m4.md}})
define({{__env__}}, {{jsdom}})dnl
include({{results.m4.md}})
