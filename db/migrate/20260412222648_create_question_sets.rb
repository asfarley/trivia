class CreateQuestionSets < ActiveRecord::Migration[8.1]
  def change
    create_table :question_sets do |t|
      t.integer :user_id
      t.string :title, null: false
      t.text :description
      t.integer :visibility, null: false, default: 0   # enum: private/public/pinned
      t.integer :looseness, null: false, default: 1    # enum: exact/case_insensitive/fuzzy/very_fuzzy

      t.timestamps
    end

    add_index :question_sets, :user_id
    add_index :question_sets, :visibility
  end
end
