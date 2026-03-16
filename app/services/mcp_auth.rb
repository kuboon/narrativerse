class McpAuth
  PURPOSE = :mcp_user
  EXPIRES_IN = 7.days

  class << self
    def sign_user_id(user_id)
      verifier.generate(user_id, purpose: PURPOSE, expires_in: EXPIRES_IN)
    end

    def verify_user_id(signature)
      return if signature.blank?

      verifier.verified(signature, purpose: PURPOSE)
    end

    private

    def verifier
      Rails.application.message_verifier(PURPOSE)
    end
  end
end
