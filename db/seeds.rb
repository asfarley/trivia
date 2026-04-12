# Sample data for development
user = User.find_or_create_by!(email: "admin@example.com") do |u|
  u.password = "password123"
  u.admin = true
end

qs = QuestionSet.find_or_create_by!(title: "World Capitals") do |q|
  q.user = user
  q.visibility = :pinned
  q.looseness = :case_insensitive
  q.description = "Test your knowledge of world capitals."
end

[
  [ "What is the capital of France?", "Paris" ],
  [ "What is the capital of Japan?", "Tokyo" ],
  [ "What is the capital of Australia?", "Canberra" ],
  [ "What is the capital of Brazil?", "Brasília" ],
  [ "What is the capital of Canada?", "Ottawa" ]
].each.with_index(1) do |(body, answer), pos|
  qs.questions.find_or_create_by!(body: body) do |q|
    q.answer = answer
    q.position = pos
  end
end

puts "Seeded: #{user.email} / password123"
puts "Question set: #{qs.title} (#{qs.questions.count} questions)"
