# frozen_string_literal: true

module SubdomainTenant
  extend ActiveSupport::Concern

  included do
    before_action :set_current_tenant
  end

  private

  def set_current_tenant
    subdomain = request_subdomain
    return ActsAsTenant.current_tenant = nil if subdomain.blank?

    school = School.find_by(subdomain: subdomain)
    return render_tenant_not_found unless school

    ActsAsTenant.current_tenant = school
  end

  def request_subdomain
    host = request.host.to_s.downcase

    if host.end_with?(".localhost")
      return host.delete_suffix(".localhost").split(".").first
    end

    base = ENV.fetch("APP_HOST", "shikshaportal.in")
    return host.split(".").first if host.end_with?(".#{base}") && host != base

    nil
  end

  def render_tenant_not_found
    render json: { error: "School not found for this subdomain" }, status: :not_found
  end
end
