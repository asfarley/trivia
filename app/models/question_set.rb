class QuestionSet < ApplicationRecord
  belongs_to :user, optional: true
  has_many :questions, -> { order(:position, :id) }, dependent: :destroy

  enum :visibility, { draft: 0, listed: 1, pinned: 2 }
  enum :looseness, { exact: 0, case_insensitive: 1, fuzzy: 2, very_fuzzy: 3, numeric_approximate: 4 }

  validates :title, presence: true

  scope :visible_to_all, -> { where(visibility: [ :listed, :pinned ]) }
  scope :featured, -> { where(visibility: :pinned) }
end
