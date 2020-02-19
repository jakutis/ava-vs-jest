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
