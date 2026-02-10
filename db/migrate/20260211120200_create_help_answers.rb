class CreateHelpAnswers < ActiveRecord::Migration[7.2]
  def change
    create_table :help_answers do |t|
      t.bigint :help_request_id, null: false
      t.bigint :admin_id, null: false
      t.text :answer, null: false

      t.timestamps
    end

    add_index :help_answers, :help_request_id, unique: true
    add_index :help_answers, :admin_id
    add_foreign_key :help_answers, :help_requests
    add_foreign_key :help_answers, :members, column: :admin_id
  end
end
