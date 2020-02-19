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
