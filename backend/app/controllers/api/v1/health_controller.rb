module Api
  module V1
    class HealthController < ApplicationController
      skip_before_action :set_current_tenant

      def show
        render json: {
          status: "ok",
          app: "shikshaportal-api",
          timestamp: Time.current.iso8601,
          gallery_table_ready: gallery_table_ready?
        }
      end

      private

      def gallery_table_ready?
        ActiveRecord::Base.connection.data_source_exists?("gallery_photos")
      rescue StandardError
        false
      end
    end
  end
end
