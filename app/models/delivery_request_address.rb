class DeliveryRequestAddress
  include ActiveModel::Model
  include ActiveModel::Attributes

  ATTRIBUTES = %w[
    line1 line2 city county_id nearest_town building_name floor door
    instructions postal_code country_id latitude longitude
  ].freeze

  attribute :line1, :string
  attribute :line2, :string
  attribute :city, :string
  attribute :county_id, :string
  attribute :nearest_town, :string
  attribute :building_name, :string
  attribute :floor, :string
  attribute :door, :string
  attribute :instructions, :string
  attribute :postal_code, :string
  attribute :country_id, :string
  attribute :latitude, :decimal
  attribute :longitude, :decimal

  validates :line1, :city, presence: true
  validates :latitude, presence: true,
    numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, presence: true,
    numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validate :county_must_exist
  validate :country_must_exist
  validate :county_belongs_to_country

  def self.from(value)
    return value if value.is_a?(self)

    new(value || {})
  end

  def id
    nil
  end

  def persisted?
    false
  end

  def country
    @country ||= Country.find_by(id: country_id) if country_id.present?
  end

  def county
    @county ||= County.find_by(id: county_id) if county_id.present?
  end

  def coordinates
    [latitude.to_f, longitude.to_f]
  end

  def to_h
    ATTRIBUTES.index_with { |attribute| public_send(attribute) }.compact
  end

  private

  def county_must_exist
    errors.add(:county, :required) if county_id.present? && county.nil?
  end

  def country_must_exist
    errors.add(:country, :required) if country_id.present? && country.nil?
  end

  def county_belongs_to_country
    return unless county && country && county.country_id != country.id

    errors.add(:county, "does not belong to the selected country")
  end
end
