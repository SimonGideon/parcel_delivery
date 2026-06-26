class User < ApplicationRecord
  has_secure_password

  has_many :delivery_requests, dependent: :restrict_with_error

  enum :role, { customer: 0, driver: 1 }, default: :customer

  EMAIL_FORMAT = URI::MailTo::EMAIL_REGEXP

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: EMAIL_FORMAT }

  scope :customers, -> { where(role: :customer, type: nil) }

  before_save { email&.downcase! }
end
