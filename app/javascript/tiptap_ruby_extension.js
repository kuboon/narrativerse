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
        renderHTML: attributes => ({
          'data-ruby': attributes.reading,
        }),
      },
    }
  },

  parseHTML() {
    return [
      {
        tag: 'ruby',
      },
    ]
  },

  renderHTML({ HTMLAttributes }) {
    const { reading, ...rest } = HTMLAttributes

    const children = [0]
    if (reading) {
      children.push(['rt', {}, reading])
    }

    return [
      'ruby',
      mergeAttributes(rest),
      ...children,
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
