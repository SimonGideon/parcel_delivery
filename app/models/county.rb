class County < ApplicationRecord
  belongs_to :country
  has_many :addresses, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :country_id }
end
