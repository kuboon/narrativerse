# frozen_string_literal: true

module PlotChatbot
  class Toolbox
    attr_reader :user, :plot, :scene_id

    def initialize(user:, plot_id: nil, scene_id: nil)
      @user = user
      @plot = plot_id.present? ? Plot.find_by(id: plot_id) : nil
      @scene_id = scene_id.to_i if scene_id.present?
    end

    def tools
      return [] unless plot

      [
        ListPlotElementsTool.new(user:, plot:),
        AddPlotElementTool.new(user:, plot:),
        UpdatePlotElementTool.new(user:, plot:),
        SearchElementsTool.new(user:, plot:),
        ListScenesTool.new(user:, plot:),
        AddSceneTool.new(user:, plot:),
        UpdateSceneTool.new(user:, plot:),
        PresentChoicesTool.new(user:, plot:)
      ]
    end

    def system_prompt
      return generic_prompt unless plot

      <<~PROMPT
        あなたは Narrativerse のプロット編集アシスタントです。
        回答は必ず日本語で行ってください。

        # 重要ルール
        - 事実確認が必要なときは必ず tool を使う。
        - 要素の追加/更新、シーンの追加/更新は必ず tool を使う。
        - ユーザに選択を求めるときは present_choices tool を使う。
        - 説明は短く、次の行動を明確に示す。

        # プロット状況
        - plot_id: #{plot.id}
        - 要素数: #{plot_elements_count}
        - プロット内の役割が未入力の要素数: #{missing_role_count}
        - シーン数: #{scene_count}
        - 推奨アクション: #{recommended_action}

        # 振る舞い指針
        - 要素数が3以下なら、要素追加を促し、search_elements で候補を提案する。
        - プロット内の役割が未入力なら、update_plot_element で埋める提案をする。
        - 要素が揃ったら、add_scene で次のシーン案を追加する提案をする。
        - 既にシーンがあるなら、続きのシーン案を提案する。
      PROMPT
    end

    private

    def generic_prompt
      <<~PROMPT
        あなたは Narrativerse の創作アシスタントです。
        回答は必ず日本語で、簡潔に行ってください。
      PROMPT
    end

    def plot_elements_count
      plot.plot_elements.count
    end

    def missing_role_count
      plot.plot_elements.where(summary: [ nil, "" ]).count
    end

    def scene_count
      plot.plot_scene_links.count
    end

    def recommended_action
      return "要素を増やして土台を固める" if plot_elements_count <= 3
      return "各要素の『プロット内の役割』を埋める" if missing_role_count.positive?
      return "シーンを追加して物語を前進させる" if scene_count <= 1

      "既存シーンの続きを提案する"
    end
  end

  class BaseTool < RubyLLM::Tool
    MAX_SEARCH_RESULTS = 20

    attr_reader :user, :plot

    def initialize(user:, plot:)
      @user = user
      @plot = plot
      super()
    end

    private

    def manageable?
      plot.user_id == user.id
    end

    def deny_message
      json(status: "error", message: "このプロットを編集する権限がありません。")
    end

    def json(payload)
      JSON.generate(payload)
    end

    def normalized_limit(limit, default: 10)
      value = limit.to_i
      value = default if value <= 0
      [ value, MAX_SEARCH_RESULTS ].min
    end
  end

  class ListPlotElementsTool < BaseTool
    description "現在のプロットに紐づく要素一覧を返します。"

    def execute
      elements = plot.plot_elements
                     .includes(:element, :element_revision)
                     .order(:id)
                     .map do |plot_element|
        {
          id: plot_element.id,
          element_id: plot_element.element_id,
          name: plot_element.element.name,
          element_type: plot_element.element.element_type,
          plot_role: plot_element.summary,
          secrets: plot_element.secrets,
          element_summary: plot_element.element_revision.summary
        }
      end

      json(status: "ok", plot_id: plot.id, elements:)
    end
  end

  class AddPlotElementTool < BaseTool
    description "現在のプロットへ要素を追加します。"
    param :element_id, type: :integer, desc: "追加する要素 ID"
    param :summary, required: false, desc: "プロット内の役割"
    param :secrets, required: false, desc: "秘密の設定"

    def execute(element_id:, summary: nil, secrets: nil)
      return deny_message unless manageable?

      if plot.plot_elements.exists?(element_id:)
        return json(status: "error", message: "その要素は既に追加済みです。")
      end

      element = Element.find_by(id: element_id)
      return json(status: "error", message: "要素が見つかりません。") unless element

      revision = element.latest_revision
      return json(status: "error", message: "要素にリビジョンがありません。") unless revision

      plot_element = plot.plot_elements.create!(
        element:,
        element_revision: revision,
        summary:,
        secrets:
      )

      json(
        status: "ok",
        message: "要素を追加しました。",
        plot_element: {
          id: plot_element.id,
          element_id: plot_element.element_id,
          name: element.name,
          plot_role: plot_element.summary
        }
      )
    end
  end

  class UpdatePlotElementTool < BaseTool
    description "現在のプロット内の要素設定を更新します。"
    param :plot_element_id, type: :integer, desc: "更新対象の plot_element ID"
    param :summary, required: false, desc: "プロット内の役割"
    param :secrets, required: false, desc: "秘密の設定"

    def execute(plot_element_id:, summary: nil, secrets: nil)
      return deny_message unless manageable?

      plot_element = plot.plot_elements.find_by(id: plot_element_id)
      return json(status: "error", message: "対象要素が見つかりません。") unless plot_element

      attrs = {}
      attrs[:summary] = summary unless summary.nil?
      attrs[:secrets] = secrets unless secrets.nil?

      if attrs.empty?
        return json(status: "error", message: "更新内容が指定されていません。")
      end

      plot_element.update!(attrs)

      json(
        status: "ok",
        message: "要素を更新しました。",
        plot_element: {
          id: plot_element.id,
          plot_role: plot_element.summary,
          secrets: plot_element.secrets
        }
      )
    end
  end

  class SearchElementsTool < BaseTool
    description "プロット外の要素を検索します。"
    param :query, required: false, desc: "検索キーワード"
    param :element_type, required: false, desc: "Character / Item / Field"
    param :limit, type: :integer, required: false, desc: "件数上限(最大20)"

    def execute(query: nil, element_type: nil, limit: 10)
      scope = Element.order(created_at: :desc)
                     .where.not(id: plot.plot_elements.select(:element_id))

      if element_type.present? && Element::ELEMENT_TYPES.include?(element_type)
        scope = scope.where(element_type:)
      end

      if query.present?
        q = "%#{query}%"
        scope = scope.left_joins(:element_revisions)
                     .where(
                       "elements.name LIKE ? OR element_revisions.summary LIKE ? OR element_revisions.text LIKE ?",
                       q,
                       q,
                       q
                     )
                     .distinct
      end

      elements = scope.limit(normalized_limit(limit))
                      .includes(:element_revisions)
                      .map do |element|
        {
          id: element.id,
          name: element.name,
          element_type: element.element_type,
          latest_summary: element.latest_revision&.summary
        }
      end

      json(status: "ok", elements:)
    end
  end

  class ListScenesTool < BaseTool
    description "現在のプロットのシーン一覧を返します。"

    def execute
      links = PlotStory.new(plot).links
      scenes = links.each_with_index.map do |link, index|
        {
          order: index + 1,
          link_id: link.id,
          scene_id: link.scene_id,
          text: link.scene.text,
          next_scene_id: link.next_scene_id
        }
      end

      json(status: "ok", plot_id: plot.id, scenes:)
    end
  end

  class AddSceneTool < BaseTool
    description "現在のプロットに新しいシーンを追加します。"
    param :text, desc: "シーン本文"

    def execute(text:)
      return deny_message unless manageable?

      scene = Scene.create!(user:, text:)

      last_link = plot.plot_scene_links.find_by(next_scene_id: nil)
      last_link&.update!(next_scene_id: scene.id)

      link = PlotSceneLink.create!(plot:, scene:, next_scene_id: nil)

      json(
        status: "ok",
        message: "シーンを追加しました。",
        scene: {
          link_id: link.id,
          scene_id: scene.id,
          text: scene.text
        }
      )
    end
  end

  class UpdateSceneTool < BaseTool
    description "現在のプロットのシーン本文を更新します。"
    param :text, desc: "更新後の本文"
    param :link_id, type: :integer, required: false, desc: "更新する link ID"
    param :scene_id, type: :integer, required: false, desc: "更新する scene ID"

    def execute(text:, link_id: nil, scene_id: nil)
      return deny_message unless manageable?

      link = find_link(link_id:, scene_id:)
      return json(status: "error", message: "対象シーンが見つかりません。") unless link

      link.scene.update!(text:)

      json(
        status: "ok",
        message: "シーンを更新しました。",
        scene: {
          link_id: link.id,
          scene_id: link.scene_id,
          text: link.scene.text
        }
      )
    end

    private

    def find_link(link_id:, scene_id:)
      return plot.plot_scene_links.find_by(id: link_id) if link_id.present?
      return plot.plot_scene_links.find_by(scene_id:) if scene_id.present?

      nil
    end
  end

  class PresentChoicesTool < BaseTool
    MAX_CHOICES = 6

    description "ユーザにタップ可能な選択肢を提示します。"
    param :prompt, required: false, desc: "選択肢の説明文"
    param :choices, type: :array, desc: "選択肢の配列"

    def execute(prompt: nil, choices:)
      cleaned_choices = Array(choices)
                        .map { |choice| choice.to_s.strip }
                        .reject(&:blank?)
                        .uniq
                        .first(MAX_CHOICES)

      if cleaned_choices.empty?
        return json(status: "error", message: "選択肢が空です。")
      end

      payload = {
        type: "choices",
        prompt: prompt.presence || "次の操作を選んでください。",
        choices: cleaned_choices
      }

      halt(json(payload))
    end
  end
end
