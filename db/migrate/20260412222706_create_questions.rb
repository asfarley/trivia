class CreateQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :questions do |t|
      t.integer :question_set_id, null: false
      t.text :body, null: false
      t.text :answer, null: false
      t.integer :position

      t.timestamps
    end

    add_index :questions, :question_set_id
  end
end
