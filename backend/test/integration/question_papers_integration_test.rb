# frozen_string_literal: true

require "test_helper"

class QuestionPapersIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    @coaching = School.find_or_create_by!(subdomain: "gurukul") do |school|
      school.assign_attributes(
        name: "Gurukul Coaching",
        institution_type: "coaching",
        default_language: "en"
      )
    end
    @coaching.update!(institution_type: "coaching")

    @admin = User.find_or_create_by!(email: "admin@gurukul.test") do |user|
      user.name = "Coaching Admin"
      user.role = "coaching_admin"
      user.school = @coaching
      user.language_preference = "en"
      user.password = "password123"
      user.password_confirmation = "password123"
    end

    @teacher = User.find_or_create_by!(email: "teacher@gurukul.test") do |user|
      user.name = "Teacher One"
      user.role = "teacher"
      user.school = @coaching
      user.language_preference = "en"
      user.password = "password123"
      user.password_confirmation = "password123"
    end

    @other_teacher = User.create!(
      name: "Teacher Two",
      email: "teacher2@gurukul.test",
      role: "teacher",
      school: @coaching,
      language_preference: "en",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  def test_teacher_can_generate_and_save_question_paper
    host! "gurukul.localhost"
    token = login_token(@teacher.email)

    post "/api/v1/question_papers/generate",
         params: {
           subject: "Mathematics",
           class_name: "Class 10",
           topic: "Quadratic Equations",
           difficulty: "mixed",
           total_marks: 50,
           language: "en",
           question_counts: { mcq: 2, short_answer: 1 }
         },
         headers: auth_headers(token),
         as: :json

    assert_response :success
    generated = JSON.parse(response.body)["generated"]
    assert generated["questions"].size == 3

    post "/api/v1/question_papers",
         params: {
           question_paper: {
             title: generated["paper_title"],
             subject: generated["subject"],
             class_name: generated["class_name"],
             topic: generated["topic"],
             difficulty: generated["difficulty"],
             language: generated["language"],
             total_marks: generated["total_marks"],
             questions: generated["questions"]
           }
         },
         headers: auth_headers(token),
         as: :json

    assert_response :created
    paper_id = JSON.parse(response.body).dig("question_paper", "id")
    assert paper_id.present?
  end

  def test_teacher_cannot_delete_question_paper
    host! "gurukul.localhost"
    ActsAsTenant.with_tenant(@coaching) do
      paper = QuestionPaper.create!(
        school: @coaching,
        teacher: @other_teacher,
        title: "Sample Paper",
        subject: "Physics",
        class_name: "JEE",
        topic: "Kinematics",
        difficulty: "medium",
        language: "en",
        total_marks: 40,
        questions: [{ "id" => "q1", "type" => "mcq", "question" => "Q?", "marks" => 4, "difficulty" => "easy", "correct_answer" => "A", "options" => %w[A B C D] }]
      )

      token = login_token(@teacher.email)
      delete "/api/v1/question_papers/#{paper.id}",
             headers: auth_headers(token),
             as: :json

      assert_response :forbidden
    end
  end

  def test_coaching_admin_can_delete_any_paper
    host! "gurukul.localhost"
    ActsAsTenant.with_tenant(@coaching) do
      paper = QuestionPaper.create!(
        school: @coaching,
        teacher: @teacher,
        title: "Delete Me",
        subject: "Chemistry",
        class_name: "NEET",
        topic: "Organic",
        difficulty: "hard",
        language: "en",
        total_marks: 30,
        questions: [{ "id" => "q1", "type" => "short_answer", "question" => "Explain.", "marks" => 5, "difficulty" => "hard", "correct_answer" => "Answer", "model_answer" => "Points" }]
      )

      token = login_token(@admin.email)
      delete "/api/v1/question_papers/#{paper.id}",
             headers: auth_headers(token),
             as: :json

      assert_response :no_content
    end
  end

  def test_school_tenant_cannot_access_question_papers
    host! "greenvalley.localhost"
    token = login_token("principal@greenvalley.test")

    post "/api/v1/question_papers/generate",
         params: {
           subject: "Math",
           class_name: "10",
           topic: "Algebra",
           difficulty: "easy",
           total_marks: 20,
           language: "en",
           question_counts: { mcq: 2 }
         },
         headers: auth_headers(token),
         as: :json

    assert_response :forbidden
  end

  private

  def login_token(email)
    post api_v1_user_session_path,
         params: { user: { email: email, password: "password123" } },
         as: :json
    assert_response :success
    response.headers["Authorization"]&.delete_prefix("Bearer ")
  end

  def auth_headers(token)
    { "Authorization" => "Bearer #{token}" }
  end
end
