class TaskAssignment < ApplicationRecord
  belongs_to :task
  belongs_to :member
  
  validates :task_id, uniqueness: { scope: :member_id, message: "already assigned to this member" }
  
  before_create :set_assigned_at
  
  private
  
  def set_assigned_at
    self.assigned_at ||= Time.current
  end
end