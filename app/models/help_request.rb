class HelpRequest < ApplicationRecord
  STATUS_OPEN = 'open'
  STATUS_ANSWERED = 'answered'

  belongs_to :requester, class_name: 'Member'
  belongs_to :admin, class_name: 'Member'
  has_one :help_answer, dependent: :destroy

  validates :question, presence: true
  validates :status, inclusion: { in: [STATUS_OPEN, STATUS_ANSWERED] }
end
