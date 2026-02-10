class HelpAnswer < ApplicationRecord
  belongs_to :help_request
  belongs_to :admin, class_name: 'Member'

  validates :answer, presence: true
end
