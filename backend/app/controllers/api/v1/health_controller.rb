module Api
  module V1
    class HealthController < ApplicationController
      skip_before_action :set_current_tenant

      def show
        render json: {
          status: "ok",
          app: "shikshaportal-api",
          timestamp: Time.current.iso8601
        }
      end
    end
  end
end
