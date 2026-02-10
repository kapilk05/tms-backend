class AddCompletionFieldsToTaskAssignments < ActiveRecord::Migration[7.2]
  def change
    add_column :task_assignments, :completed_at, :datetime
    add_column :task_assignments, :completion_comment, :text
  end
end
