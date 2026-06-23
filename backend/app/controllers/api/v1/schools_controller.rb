# frozen_string_literal: true

module Api
  module V1
    class SchoolsController < ApplicationController
      def current
        school = ActsAsTenant.current_tenant
        return render json: { error: "No tenant for this subdomain" }, status: :not_found unless school

        render json: {
          id: school.id,
          name: school.name,
          subdomain: school.subdomain
        }
      end
    end
  end
end
