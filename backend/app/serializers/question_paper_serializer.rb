# frozen_string_literal: true

class QuestionPaperSerializer
  def self.as_json(paper, include_teacher: false)
    payload = {
      id: paper.id,
      coaching_center_id: paper.school_id,
      title: paper.title,
      subject: paper.subject,
      class_name: paper.class_name,
      topic: paper.topic,
      difficulty: paper.difficulty,
      language: paper.language,
      total_marks: paper.total_marks,
      questions: paper.questions,
      created_at: paper.created_at,
      updated_at: paper.updated_at,
      teacher_id: paper.teacher_id
    }

    if include_teacher
      payload[:teacher_name] = paper.teacher&.name
    end

    payload
  end
end
