class PagesController < ApplicationController
  def landing
    @featured_sets = QuestionSet.featured.order(updated_at: :desc)
  end
end
