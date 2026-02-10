class Member < ApplicationRecord
  belongs_to :role
  has_many :task_assignments, dependent: :destroy
  has_many :tasks, through: :task_assignments
  has_many :created_tasks, class_name: 'Task', foreign_key: 'created_by_id', dependent: :destroy
  has_many :requested_help_requests, class_name: 'HelpRequest', foreign_key: 'requester_id', dependent: :destroy
  has_many :assigned_help_requests, class_name: 'HelpRequest', foreign_key: 'admin_id', dependent: :destroy
  has_many :help_answers, foreign_key: 'admin_id', dependent: :destroy
  
  has_secure_password
  
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, if: :password_digest_changed?
end