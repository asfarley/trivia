class Question < ApplicationRecord
  ROLLING_DAYS = 30

  belongs_to :question_set
  has_many :attempts, dependent: :destroy

  validates :body, :answer, presence: true

  def correct?(submitted)
    submitted = submitted.to_s.strip
    correct_answer = answer.to_s.strip

    case question_set.looseness
    when "exact"            then submitted == correct_answer
    when "case_insensitive" then submitted.downcase == correct_answer.downcase
    when "fuzzy"            then normalize(submitted) == normalize(correct_answer) ||
                                 numeric_match?(submitted, correct_answer)
    when "very_fuzzy"       then fuzzy_match?(submitted, correct_answer)
    else false
    end
  end

  def accuracy(user, rolling: false)
    scope = attempts.where(user_id: user.id)
    scope = scope.where(answered_at: ROLLING_DAYS.days.ago..) if rolling
    counts = scope.group(:correct).count
    total = counts.values.sum
    return nil if total.zero?
    counts[true].to_f / total
  end

  private

  def normalize(str)
    str.downcase
       .gsub(/[^a-z0-9\s]/, "")
       .gsub(/\s+/, " ")
       .strip
  end

  def numeric_match?(a, b)
    (Float(a) - Float(b)).abs < 0.01
  rescue ArgumentError, TypeError
    false
  end

  def fuzzy_match?(submitted, correct)
    a = normalize(submitted)
    b = normalize(correct)
    return true if a == b
    return true if numeric_match?(submitted, correct)
    max_dist = [ (b.length * 0.2).ceil, 1 ].max.clamp(1, 3)
    levenshtein(a, b) <= max_dist
  end

  def levenshtein(a, b)
    return b.length if a.empty?
    return a.length if b.empty?

    matrix = Array.new(a.length + 1) do |i|
      Array.new(b.length + 1) do |j|
        i.zero? ? j : (j.zero? ? i : 0)
      end
    end

    (1..a.length).each do |i|
      (1..b.length).each do |j|
        cost = a[i - 1] == b[j - 1] ? 0 : 1
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost
        ].min
      end
    end

    matrix[a.length][b.length]
  end
end
