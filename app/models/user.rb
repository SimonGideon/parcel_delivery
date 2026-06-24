class User < ApplicationRecord
  has_secure_password

  has_many :delivery_requests, dependent: :restrict_with_error

  EMAIL_FORMAT = URI::MailTo::EMAIL_REGEXP

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: EMAIL_FORMAT }

  before_save { email&.downcase! }
end
