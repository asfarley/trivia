class Attempt < ApplicationRecord
  belongs_to :question
  belongs_to :user, optional: true

  validates :correct, inclusion: { in: [ true, false ] }
  validates :answered_at, presence: true
end
