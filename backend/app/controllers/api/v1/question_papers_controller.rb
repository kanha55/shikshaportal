# frozen_string_literal: true

module Api
  module V1
    class QuestionPapersController < ApplicationController
      include CoachingStaffAuth

      before_action :set_question_paper, only: %i[show update]
      before_action :authorize_paper_access!, only: %i[show update]

      def generate
        result = AiQuestionPaperGeneratorService.new(
          coaching_center: ActsAsTenant.current_tenant,
          subject: generation_params[:subject],
          class_name: generation_params[:class_name],
          topic: generation_params[:topic],
          question_counts: generation_params[:question_counts],
          difficulty: generation_params[:difficulty],
          total_marks: generation_params[:total_marks],
          language: generation_params[:language],
          instructions: generation_params[:instructions]
        ).call

        # Track generation for hourly rate limiting (not a saved paper).
        QuestionPaperGenerationLog.create!(
          school: ActsAsTenant.current_tenant,
          user: current_user
        )

        render json: {
          generated: result,
          usage: {
            this_hour: AiQuestionPaperGeneratorService.hourly_usage_for(ActsAsTenant.current_tenant),
            limit: AiQuestionPaperGeneratorService::HOURLY_CAP
          }
        }
      rescue AiQuestionPaperGeneratorService::GenerationError => e
        status = e.code == :hourly_limit ? :too_many_requests : :unprocessable_entity
        render json: { errors: [e.message] }, status: status
      rescue StandardError => e
        Rails.logger.error("[QuestionPapersController#generate] #{e.class}: #{e.message}")
        render json: { errors: [I18n.t("services.question_paper.service_unavailable")] },
               status: :internal_server_error
      end

      def index
        papers = scoped_papers.recent
        papers = papers.filter_by_subject(params[:subject])
        papers = papers.filter_by_class_name(params[:class_name])
        papers = papers.filter_by_date(params[:date])

        render json: {
          question_papers: papers.map { |paper| serialize(paper, include_teacher: current_user.coaching_admin?) }
        }
      end

      def show
        render json: { question_paper: serialize(@question_paper, include_teacher: current_user.coaching_admin?) }
      end

      def create
        paper = QuestionPaper.new(persisted_params)
        paper.school = ActsAsTenant.current_tenant
        paper.teacher = current_user
        paper.title ||= QuestionPaper.auto_title(
          subject: paper.subject,
          class_name: paper.class_name,
          topic: paper.topic
        )

        if paper.save
          render json: { question_paper: serialize(paper) }, status: :created
        else
          render json: { errors: paper.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @question_paper.update(persisted_params)
          render json: { question_paper: serialize(@question_paper) }
        else
          render json: { errors: @question_paper.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        paper = QuestionPaper.find(params[:id])
        unless current_user.coaching_admin?
          render json: { error: I18n.t("errors.forbidden") }, status: :forbidden and return
        end

        paper.destroy!
        head :no_content
      rescue ActiveRecord::RecordNotFound
        render json: { error: I18n.t("errors.not_found") }, status: :not_found
      end

      private

      def scoped_papers
        if current_user.coaching_admin?
          QuestionPaper.all
        else
          QuestionPaper.for_teacher(current_user.id)
        end
      end

      def set_question_paper
        @question_paper = scoped_papers.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: I18n.t("errors.not_found") }, status: :not_found and return
      end

      def authorize_paper_access!
        return if current_user.coaching_admin?
        return if @question_paper.teacher_id == current_user.id

        render json: { error: I18n.t("errors.forbidden") }, status: :forbidden
      end

      def generation_params
        params.permit(
          :subject,
          :class_name,
          :topic,
          :difficulty,
          :total_marks,
          :language,
          :instructions,
          question_counts: QuestionPaper::QUESTION_TYPES
        )
      end

      def persisted_params
        source = params[:question_paper].presence || params
        source.permit(
          :title,
          :subject,
          :class_name,
          :topic,
          :difficulty,
          :language,
          :total_marks,
          questions: [
            :id,
            :type,
            :question,
            :correct_answer,
            :model_answer,
            :marks,
            :difficulty,
            { options: [] }
          ]
        )
      end

      def serialize(paper, include_teacher: false)
        QuestionPaperSerializer.as_json(paper, include_teacher: include_teacher)
      end
    end
  end
end
