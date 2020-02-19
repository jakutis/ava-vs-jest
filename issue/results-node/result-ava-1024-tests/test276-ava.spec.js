const test = require('ava');
const { expect } = require('chai')

for (var i = 1; i <= Number(process.env.FATJEST_COUNT); i++) {
  test('product #' + i, t => {
    expect('hi').to.equal('hi')
    t.pass()
  })
}
