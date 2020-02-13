const test = require('ava');

for (var i = 1; i <= Number(process.env.FATJEST_COUNT); i++) {
  test('product #' + i, t => {
    t.pass()
  })
}
