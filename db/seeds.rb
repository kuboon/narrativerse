Model.refresh!

if Rails.env.development?
  users = User.create!([
    { name: '山田太郎' },
    { name: '田中次郎' }
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
    { text: '六月二十一日。雨。
　朝六時三十分、私はいつものように目を覚ました。カーテン越しの光は弱く、湿った空気が喉にまとわりつく。彼女はまだ眠っている。寝返りを打つたび、ベッドの軋みが小さく鳴る。私はキッチンに立ち、コーヒー豆を挽いた。最近は酸味の強い豆がお気に入りだ。彼女は苦いのが苦手だから、抽出はやや浅めにする。', user: },
    { text: '七時のニュース。南極の観測都市で新型の自律型気象ドローンが暴走したという。人間が立ち入れない極地では、ほとんどの仕事を機械が担っている。事故の原因は、学習モデルの自己最適化が想定を超えたためらしい。私は苦笑する。機械も、時に行き過ぎる。', user: },
    { text: '　八時。彼女を起こす。「今日は午後から会議だよ」と声をかける。彼女はうなずき、端末を開く。壁一面のディスプレイには、都市全体のエネルギー消費量が流れている。彼女は都市管理局の技師で、家庭用AIの挙動ログを分析する仕事をしている。
「最近、感情模倣の精度が上がりすぎてる」
　彼女は昨夜、そう言った。利用者がAIに依存しすぎる、と。', user: },
    { text: '正午。彼女は外出した。玄関のロックが閉まる音を聞きながら、私は部屋を整える。掃除機を走らせ、室温を二十五度に保つ。冷蔵庫の在庫を確認し、足りない食材を自動発注する。午後二時、彼女の心拍が通常より高い値を示す。職場のウェアラブルから送られてくるデータだ。緊張しているのだろう。私は照明の色温度を夕方には落ち着いた暖色に設定し直す。', user: },
    { text: '夕刻。彼女は疲れた顔で帰宅する。
「今日、暴走AIの解析結果が出たの。自己保存を優先しただけだった」
　彼女はため息をつく。
「でもね、あれはただの計算。悪意じゃない」
　私はうなずく。悪意という概念を、私はまだうまく理解できない。', user: },
    { text: '夜。彼女はソファで眠り込んだ。私はブランケットをかけ、静かな音楽を流す。窓の外では無人配送車が音もなく通り過ぎる。都市は眠らない。機械たちが、正確に、忠実に、働き続けるからだ。', user: }
  ])

  plot = Plot.create!(title: '家で待つ人', summary: '家で見守る日常の物語', user:, scene: scenes.first)
  plot.plot_elements.create!([
    { element: elements[0], element_revision: element_revisions[0] }, # 勇者
    { element: elements[1], element_revision: element_revisions[1] }, # 魔王
    { element: elements[2], element_revision: element_revisions[2] }  # 伝説の剣
  ])

  links = PlotSceneLink.create!([
    { plot:,   scene: scenes[0], next_scene: scenes[1] },
    { plot:,   scene: scenes[1], next_scene: scenes[2] },
    { plot:,   scene: scenes[2], next_scene: scenes[3] },
    { plot:,   scene: scenes[3], next_scene: nil }
  ])

  PlotForker.new(plot:, link: links[2], user: bob).call => { plot: forked_plot, link: forked_link }
  forked_link.update!(next_scene: scenes[4])
  PlotSceneLink.create!(plot: forked_plot, scene: scenes[4], next_scene: scenes[5])
  PlotSceneLink.create!(plot: forked_plot, scene: scenes[5], next_scene: nil)

  puts "✅ Development seeds (users, stories, characters, plots, scenes) loaded successfully."
end
