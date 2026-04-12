class QuestionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_question_set
  before_action :require_owner!

  def index
    @questions = @question_set.questions
  end

  def create
    @question = @question_set.questions.build(question_params)
    @question.position = @question_set.questions.maximum(:position).to_i + 1
    if @question.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to question_set_questions_path(@question_set) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("new_question_form", partial: "questions/form", locals: { question: @question, question_set: @question_set }) }
        format.html { redirect_to question_set_questions_path(@question_set) }
      end
    end
  end

  def update
    @question = @question_set.questions.find(params[:id])
    if @question.update(question_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to question_set_questions_path(@question_set) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("question_#{@question.id}", partial: "questions/question", locals: { question: @question, question_set: @question_set }) }
        format.html { redirect_to question_set_questions_path(@question_set) }
      end
    end
  end

  def destroy
    @question = @question_set.questions.find(params[:id])
    @question.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("question_#{@question.id}") }
      format.html { redirect_to question_set_questions_path(@question_set) }
    end
  end

  private

  def set_question_set
    @question_set = current_user.question_sets.find(params[:question_set_id])
  end

  def require_owner!
    redirect_to root_path, alert: "Not authorized." unless @question_set.user == current_user
  end

  def question_params
    params.expect(question: [ :body, :answer, :position ])
  end
end
