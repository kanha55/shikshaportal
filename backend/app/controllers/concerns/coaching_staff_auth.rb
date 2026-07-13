# frozen_string_literal: true

module CoachingStaffAuth
  extend ActiveSupport::Concern

  included do
    include JwtAuthenticatable
    before_action :authorize_coaching_staff!
    before_action :ensure_coaching_center_tenant!
  end

  private

  def authorize_coaching_staff!
    tenant = ActsAsTenant.current_tenant
    return if current_user&.coaching_staff? && current_user.school_id == tenant&.id

    render json: { error: I18n.t("errors.forbidden") }, status: :forbidden and return
  end

  def ensure_coaching_center_tenant!
    tenant = ActsAsTenant.current_tenant
    return if tenant&.coaching_center?

    render json: { error: I18n.t("errors.coaching_center_only") }, status: :forbidden and return
  end
end
