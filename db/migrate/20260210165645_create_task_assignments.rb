class CreateTaskAssignments < ActiveRecord::Migration[7.1]
    def change
      create_table :task_assignments do |t|

        t.timestamps
      end
    end
end
