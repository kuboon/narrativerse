if Rails.env.development?
  users = User.create!([
    { name: 'Alice' },
    { name: 'Bob' }
  ])
  user = users.first

  scenes = Scene.create!([
    { text: 'The hero awakens in a quiet village.', user: },
    { text: 'A mysterious map is discovered.', user: },
    { text: 'The city streets whisper secrets.', user: },
    { text: 'A shadowy figure follows the hero.', user: }
  ])

  plots = Plot.create!([
    { title: 'Heroic Quest', summary: 'The hero sets out on a journey.', user:, scene: scenes.first },
    { title: 'City Mystery', summary: 'A secret hidden in the city.', user:, scene: scenes.first }
  ])

  PlotSceneLink.create!([
    { plot: plots[0],   scene: scenes[0],  next_scene: scenes[1] },
    { plot: plots[0],   scene: scenes[1], next_scene: scenes[2] },
    { plot: plots[0],   scene: scenes[2], next_scene: scenes[3] },
    { plot: plots[1],   scene: scenes[2], next_scene: scenes[4] }
  ])

  puts "✅ Development seeds (users, stories, characters, plots, scenes) loaded successfully."
end
