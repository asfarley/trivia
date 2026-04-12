module ApplicationHelper
  def format_accuracy(value)
    return "—" if value.nil?
    "#{(value * 100).round}%"
  end
end
