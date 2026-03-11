# frozen_string_literal: true

module PlotChatbot
  module Tools
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

        halt json(payload)
      end
    end
  end
end
