class CreateHelpRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :help_requests do |t|
      t.bigint :requester_id, null: false
      t.bigint :admin_id, null: false
      t.text :question, null: false
      t.string :status, null: false, default: 'open'

      t.timestamps
    end

    add_index :help_requests, :requester_id
    add_index :help_requests, :admin_id
    add_foreign_key :help_requests, :members, column: :requester_id
    add_foreign_key :help_requests, :members, column: :admin_id
  end
end
