class Task < ApplicationRecord
  belongs_to :created_by, class_name: 'Member', foreign_key: 'created_by_id'
  has_many :task_assignments, dependent: :destroy
  has_many :assigned_members, through: :task_assignments, source: :member
  has_many :help_requests, dependent: :destroy
  
  validates :title, presence: true
  validates :status, inclusion: { in: %w[pending in_progress completed] }
  validates :priority, inclusion: { in: %w[low medium high] }, allow_nil: true
  
  # Scopes for filtering
  scope :pending, -> { where(status: 'pending') }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :completed, -> { where(status: 'completed') }
  scope :by_priority, ->(priority) { where(priority: priority) }
end