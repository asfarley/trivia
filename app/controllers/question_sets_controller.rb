class QuestionSetsController < ApplicationController
  before_action :authenticate_user!, only: [ :index, :new, :create, :edit, :update, :destroy, :pin ]
  before_action :set_question_set, only: [ :show, :edit, :update, :destroy, :study, :check_answer, :pin ]
  before_action :require_owner!, only: [ :edit, :update, :destroy ]
  before_action :require_admin!, only: [ :pin ]

  def index
    @question_sets = current_user.question_sets.order(updated_at: :desc)
  end

  def show
    @questions = @question_set.questions
  end

  def new
    @question_set = QuestionSet.new
  end

  def create
    @question_set = current_user.question_sets.build(question_set_params)
    if @question_set.save
      redirect_to question_set_questions_path(@question_set), notice: "Question set created. Add your questions below."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @question_set.update(question_set_params)
      redirect_to @question_set, notice: "Saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @question_set.destroy
    redirect_to question_sets_path, notice: "Deleted."
  end

  def study
    @question = next_question
    @session_correct = session[:study_correct].to_i
    @session_total   = session[:study_total].to_i
  end

  def check_answer
    question = @question_set.questions.find(params[:question_id])
    correct  = question.correct?(params[:answer])

    if user_signed_in?
      Attempt.create!(
        question: question,
        user: current_user,
        correct: correct,
        answered_at: Time.current
      )
    end

    session[:study_correct] = session[:study_correct].to_i + (correct ? 1 : 0)
    session[:study_total]   = session[:study_total].to_i + 1

    @question      = next_question
    @last_correct  = correct
    @last_answer   = question.answer
    @session_correct = session[:study_correct]
    @session_total   = session[:study_total]

    respond_to do |format|
      format.turbo_stream
    end
  end

  def pin
    new_visibility = @question_set.pinned? ? :listed : :pinned
    @question_set.update!(visibility: new_visibility)
    redirect_to @question_set, notice: "Visibility updated."
  end

  private

  def set_question_set
    @question_set = QuestionSet.find(params[:id])
  end

  def require_owner!
    redirect_to root_path, alert: "Not authorized." unless @question_set.user == current_user
  end

  def require_admin!
    redirect_to root_path, alert: "Not authorized." unless current_user.admin?
  end

  def question_set_params
    params.expect(question_set: [ :title, :description, :looseness, :visibility ])
  end

  def next_question
    questions = @question_set.questions.to_a
    return nil if questions.empty?

    weights = questions.map do |q|
      accuracy = user_signed_in? ? (q.accuracy(current_user, rolling: true) || 0.5) : 0.5
      weight   = 1.0 - (accuracy * 0.8)
      [ q, weight ]
    end

    total      = weights.sum { |_, w| w }
    pick       = rand * total
    cumulative = 0.0

    weights.each do |q, w|
      cumulative += w
      return q if pick <= cumulative
    end

    weights.last.first
  end
end
