import { Mark, mergeAttributes } from '@tiptap/core'

export const Ruby = Mark.create({
  name: 'ruby',

  addAttributes() {
    return {
      text: {
        default: null,
        parseHTML: element => {
          const rt = element.querySelector('rt')
          return rt ? rt.innerText : null
        },
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
    const { text, ...rest } = HTMLAttributes
    return [
      'ruby',
      mergeAttributes(rest),
      0, // The text content goes here
      ['rt', {}, text],
    ]
  },

  addCommands() {
    return {
      setRuby:
        (text) =>
        ({ commands }) => {
          return commands.setMark(this.name, { text })
        },
      toggleRuby:
        (text) =>
        ({ commands }) => {
          return commands.toggleMark(this.name, { text })
        },
      unsetRuby:
        () =>
        ({ commands }) => {
          return commands.unsetMark(this.name)
        },
    }
  },
})
