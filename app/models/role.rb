class Role < ApplicationRecord
  has_many :members, dependent: :destroy
  
  validates :name, presence: true, uniqueness: true
  
  ADMIN = 'admin'
  MANAGER = 'manager'
  USER = 'user'
end