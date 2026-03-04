import { Mark, mergeAttributes } from '@tiptap/core'

export const Ruby = Mark.create({
  name: 'ruby',
  inclusive: false,

  addAttributes() {
    return {
      reading: {
        default: null,
        parseHTML: element => {
          const fromDataAttribute = element.getAttribute('data-ruby')
          if (fromDataAttribute) return fromDataAttribute

          const rt = element.querySelector('rt')
          return rt ? rt.textContent : null
        },
        renderHTML: attributes => {
          if (!attributes.reading) return {}

          return {
            'data-ruby': attributes.reading,
          }
        },
      },
    }
  },

  parseHTML() {
    return [
      {
        tag: 'ruby',
        contentElement: element => {
          const rb = element.querySelector('rb')
          if (rb) return rb

          const fallback = element.ownerDocument.createElement('span')
          element.childNodes.forEach((childNode) => {
            if (childNode.nodeType === 1 && childNode.nodeName.toLowerCase() === 'rt') return
            fallback.appendChild(childNode.cloneNode(true))
          })

          return fallback
        },
      },
    ]
  },

  renderHTML({ HTMLAttributes }) {
    const reading = HTMLAttributes.reading ?? HTMLAttributes['data-ruby']
    const { reading: _reading, ...rest } = HTMLAttributes

    const rubyChildren = [['rb', {}, 0]]
    if (reading) {
      rubyChildren.push(['rt', {}, reading])
    }

    return [
      'ruby',
      mergeAttributes(rest),
      ...rubyChildren,
    ]
  },

  addCommands() {
    return {
      setRuby:
        (reading) =>
        ({ commands }) => {
          return commands.setMark(this.name, { reading })
        },
      toggleRuby:
        (reading) =>
        ({ commands }) => {
          return commands.toggleMark(this.name, { reading })
        },
      unsetRuby:
        () =>
        ({ commands }) => {
          return commands.unsetMark(this.name)
        },
    }
  },
})
