class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :question_sets, dependent: :nullify
  has_many :attempts, dependent: :destroy
end
