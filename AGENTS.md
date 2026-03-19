# Narrativerse Agent Notes

## General Rules
- Rails 8 app with SQLite DB
- 未リリースなのでマイグレーションやモデルの大幅な変更が可能。 db migration file も都度新規作成せず、schema.rb を直接修正OK。その際は `db:setup` を実行すること。
- UI strings are Japanese-first; locale default set to `:ja`.
- 正常系のカバレッジ100%を目指してテストを書く。
- legacy や deprecated は残さずどんどん削除。 `removed;` などのコメントは残さない。

## How to Run
- Ruby via mise: `/home/vscode/.local/bin/mise exec -- ruby -v`
- Run tests: `/home/vscode/.local/bin/mise exec -- bin/rails test`

## Definition of Done
- `bin/rails test` が全て成功すること。
- `bin/rails test:system` も全て成功すること。
- `bin/rubocop` を実行して警告がないこと。
- 以上が完了したら適切なコミットメッセージでコミットする。 (push はしない)

# 権限
app/policies に集約する

## PlotStory
Plot から Scene の配列を生成する。

## Important Implementation Details
- Reading URL: `/reader/:plot_id(/:link_id)`
- PlotStory builds a full story-flow by walking links (and parents) and returns focus link + branches.
- PlotEditor duplicates a plot from a specific scene and links to parent plot.
- ElementRevisionManager updates owned plot elements to latest revision and prunes unreferenced revisions.
- Locale config: `config.i18n.default_locale = :ja` in `config/application.rb`.
- Pundit導入済み（Plot/Elementポリシーで作成・編集・分岐を制御）。
