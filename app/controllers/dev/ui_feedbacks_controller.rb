class Dev::UiFeedbacksController < ApplicationController
  before_action :require_development_or_test!
  before_action :require_local_request!

  def create
    payload = feedback_params.to_h
    payload["captured_at"] ||= Time.current.iso8601

    FileUtils.mkdir_p(feedback_dir)
    File.write(latest_path, JSON.pretty_generate(payload))
    File.open(history_path, "a") { |file| file.puts(payload.to_json) }
    copilot_kicked = kick_copilot_cli

    render json: {
      status: "ok",
      saved_to: latest_path.relative_path_from(Rails.root).to_s,
      copilot_cli_kicked: copilot_kicked
    }
  rescue JSON::GeneratorError, Errno::EACCES => error
    render json: { status: "error", message: error.message }, status: :unprocessable_entity
  end

  private

  def require_development_or_test!
    return if Rails.env.development? || Rails.env.test?

    head :not_found
  end

  def require_local_request!
    return if request.local?

    head :forbidden
  end

  def feedback_params
    source = params[:ui_feedback].is_a?(ActionController::Parameters) ? params.require(:ui_feedback) : params

    source.permit(
      :captured_at,
      :request,
      :url,
      :path,
      :page_controller,
      :page_action,
      :selector,
      :tag_name,
      :element_id,
      :text,
      classes: [],
      styles: {},
      viewport: {},
      box: {}
    )
  end

  def feedback_dir
    base_dir = Rails.root.join("tmp", "ui_feedbacks")
    return base_dir unless Rails.env.test?

    base_dir.join("pid_#{Process.pid}")
  end

  def latest_path
    feedback_dir.join("latest.json")
  end

  def history_path
    feedback_dir.join("history.ndjson")
  end

  def kick_copilot_cli
    script_path = Rails.root.join("bin", "ui_feedback_to_copilot")
    return false unless script_path.exist? && script_path.executable?

    pid = Process.spawn(script_path.to_s, chdir: Rails.root.to_s, out: File::NULL, err: File::NULL)
    Process.detach(pid)
    true
  rescue StandardError => error
    Rails.logger.warn("Failed to kick Copilot CLI: #{error.class}: #{error.message}")
    false
  end
end
