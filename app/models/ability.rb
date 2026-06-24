class Ability
  include CanCan::Ability

  def initialize(principal)
    return if principal.nil?

    case principal
    when User
      user_abilities(principal)
    when Driver
      driver_abilities(principal)
    end
  end

  private

  def user_abilities(user)
    can :create, DeliveryRequest
    can :read, DeliveryRequest, user_id: user.id
  end

  def driver_abilities(driver)
    can :read, DeliveryRequest, driver_id: driver.id
    can :read, DeliveryRequest do |delivery_request|
      delivery_request.delivery_events.driver_rejected.where("metadata ->> 'driver_id' = ?", driver.id).exists?
    end
    can :accept, DeliveryRequest, driver_id: driver.id
    can :reject, DeliveryRequest, driver_id: driver.id
    can :create, DriverLocation
  end
end
