changequote(`{{', `}}')dnl
changecom(`%%`)
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

define({{__env__}}, {{node}})dnl
include({{results.m4.md}})
define({{__env__}}, {{jsdom}})dnl
include({{results.m4.md}})
