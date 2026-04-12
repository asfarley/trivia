class CreateAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :attempts do |t|
      t.integer :question_id, null: false
      t.integer :user_id                    # nullable: anonymous users never write rows
      t.boolean :correct, null: false
      t.datetime :answered_at, null: false

      t.timestamps
    end

    add_index :attempts, :question_id
    add_index :attempts, [ :user_id, :question_id ]
    add_index :attempts, [ :user_id, :answered_at ]
  end
end
