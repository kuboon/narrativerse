if Rails.env.development?
  users = User.create!([
    { name: 'Alice' },
    { name: 'Bob' }
  ])
  user = users.first
  bob = users.last

  elements = Element.create!([
    { element_type: 'Character', name: '勇者', user: user },
    { element_type: 'Character', name: '魔王', user: user },
    { element_type: 'Item', name: '伝説の剣', user: user }
  ])
  element_revisions = elements.map do |element|
    element.element_revisions.create!(revision: 1, text: "#{element.name}の説明", user:)
  end

  scenes = Scene.create!([
    { text: 'The hero awakens in a quiet village.', user: },
    { text: 'A mysterious map is discovered.', user: },
    { text: 'The city streets whisper secrets.', user: },
    { text: 'A shadowy figure follows the hero.', user: }
  ])

  plot = Plot.create!(title: 'Heroic Quest', summary: 'The hero sets out on a journey.', user:, scene: scenes.first)
  plot.plot_elements.create!([
    { element: elements[0], element_revision: element_revisions[0] }, # 勇者
    { element: elements[1], element_revision: element_revisions[1] }, # 魔王
    { element: elements[2], element_revision: element_revisions[2] }  # 伝説の剣
  ])

  links = PlotSceneLink.create!([
    { plot: plot,   scene: scenes[0], next_scene: scenes[1] },
    { plot: plot,   scene: scenes[1], next_scene: scenes[2] },
    { plot: plot,   scene: scenes[2], next_scene: scenes[3] },
    { plot: plot,   scene: scenes[3], next_scene: nil }
  ])

  PlotForker.new(plot:, link: links[2], user: bob).call

  puts "✅ Development seeds (users, stories, characters, plots, scenes) loaded successfully."
end
