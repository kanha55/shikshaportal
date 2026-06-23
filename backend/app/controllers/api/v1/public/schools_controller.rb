# frozen_string_literal: true

module Api
  module V1
    module Public
      class SchoolsController < ApplicationController
        def show
          school = ActsAsTenant.current_tenant
          return render json: { error: "School not found" }, status: :not_found unless school

          render json: {
            id: school.id,
            name: school.name,
            subdomain: school.subdomain,
            address: school.address,
            phone: school.phone,
            board: school.board,
            principal_name: school.principal_name,
            about_us: school.about_us
          }
        end
      end
    end
  end
end
