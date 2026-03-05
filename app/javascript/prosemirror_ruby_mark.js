// ProseMirror mark spec for ruby annotation
export const rubyMark = {
  attrs: { reading: { default: null } },
  inclusive: false,
  parseDOM: [
    {
      tag: "ruby",
      getAttrs(dom) {
        // data-ruby attribute
        const fromData = dom.getAttribute("data-ruby")
        if (fromData) return { reading: fromData }
        // <rt> child
        const rt = dom.querySelector("rt")
        return { reading: rt ? rt.textContent : null }
      },
    },
  ],
  toDOM(mark) {
    const reading = mark.attrs.reading
    if (reading) {
      return ["ruby", { "data-ruby": reading }, ["rb", 0], ["rt", reading]]
    }
    return ["ruby", 0]
  },
}
