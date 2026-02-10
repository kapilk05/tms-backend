class AddTaskToHelpRequests < ActiveRecord::Migration[7.2]
  def change
    add_column :help_requests, :task_id, :bigint
    add_index :help_requests, :task_id
    add_foreign_key :help_requests, :tasks
  end
end
