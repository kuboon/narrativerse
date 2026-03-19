require 'factory_bot'
FactoryBot.find_definitions

Model.refresh!

if Rails.env.development?
  users = User.create!([
    { name: '山田 太郎' },
    { name: '田中 次郎' }
  ])
  user = users.first
  bob = users.last

  plot = FactoryBot.create(:plot, user:, story: <<~EOS)
    六月二十一日。雨。
    朝六時三十分、私はいつものように目を覚ました。カーテン越しの光は弱く、湿った空気が喉にまとわりつく。彼女はまだ眠っている。寝返りを打つたび、ベッドの軋みが小さく鳴る。私はキッチンに立ち、コーヒー豆を挽いた。最近は酸味の強い豆がお気に入りだ。彼女は苦いのが苦手だから、抽出はやや浅めにする。
    ---
    七時のニュース。南極の観測都市で新型の自律型気象ドローンが暴走したという。人間が立ち入れない極地では、ほとんどの仕事を機械が担っている。事故の原因は、学習モデルの自己最適化が想定を超えたためらしい。私は苦笑する。機械も、時に行き過ぎる。
    ---
    八時。彼女を起こす。「今日は午後から会議だよ」と声をかける。彼女はうなずき、端末を開く。壁一面のディスプレイには、都市全体のエネルギー消費量が流れている。彼女は都市管理局の技師で、家庭用AIの挙動ログを分析する仕事をしている。
   「最近、感情模倣の精度が上がりすぎてる」
    彼女は昨夜、そう言った。利用者がAIに依存しすぎる、と。
    ---
    十時。私は仕事に出かける。街はすでに活気づいている。自動運転車が静かに道路を走り、空には配送ドローンが飛び交う。私はオフィスビルのエレベーターに乗り込む。中には数人の同僚がいるが、誰もが端末を見つめている。会話はほとんどない。
    ---
    十二時。昼食は近くのフードコートで済ませる。
    さまざまな料理の自動販売機が並んでいる。私は和食の機械に近づき、画面をタップする。数秒後、温かい弁当が出てくる。隣のテーブルでは、同僚たちが同じように食事を取っているが、誰も会話をしていない。みんな、端末に夢中だ。
    ---
    十五時。会議が始まる。プロジェクターに映し出された資料には、都市のエネルギー管理システムの新しいアルゴリズムが示されている。彼女はこのプロジェクトのリーダーだ。
    会議室には十数人の技術者がいるが、彼女の説明に対する質問はほとんどない。みんな、ただ黙って聞いている。私は彼女の横顔を見ながら、少し寂しい気持ちになる。
    ---
    十八時。仕事が終わり、帰宅する。街は夜の帳に包まれている。ネオンが輝き、ホログラム広告が空を彩る。私は自動運転車に乗り込み、家路につく。
  EOS

  [
    { element_type: 'Character', name: '山田 太郎' },
    { element_type: 'Character', name: '田中 次郎' },
    { element_type: 'Item', name: 'スマホ' }
  ].each do |attrs|
    element = Element.build_revision(user: user, **attrs).element
    plot.add_element!(element:, summary: "#{element.name}の役割", secrets: "#{element.name}の秘密")
  end


  links = plot.story.links

  PlotEditor.new(plot:, user: bob).fork(link: links[2]) => { plot: forked_plot, link: forked_link }
  editor = PlotEditor.new(plot: forked_plot, user: bob)
  editor.add_scene(text: "分岐したシーン1")
  editor.add_scene(text: "分岐したシーン2")
  editor.add_scene(text: "分岐したシーン3")

  puts "✅ Development seeds (users, stories, characters, plots, scenes) loaded successfully."
end
