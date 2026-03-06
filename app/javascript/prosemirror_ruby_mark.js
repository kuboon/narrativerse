// ProseMirror mark spec for ruby annotation
export const rubyMark = {
  attrs: { reading: { default: null } },
  inclusive: false,
  parseDOM: [
    {
      tag: "ruby",
      getAttrs(dom) {
        const rt = dom.querySelector("rt")
        return { reading: rt?.textContent }
      },
      contentElement(dom) {
        return dom.querySelector("span") || dom
      }
    },
  ],
  toDOM(mark) {
    const reading = mark.attrs.reading
    if (reading) {
      return ["ruby", ["span", 0], ["rt", reading]]
    }
    return ["ruby", 0]
  },
}
