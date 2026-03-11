# frozen_string_literal: true

module PlotChatbot
  class PromptBuilder
    attr_reader :plot, :scene_id

    def initialize(plot:, scene_id: nil)
      @plot = plot
      @scene_id = scene_id.to_i if scene_id.present?
    end

    def build
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
        - フォーカス scene_id: #{scene_id || "未指定"}
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
end
