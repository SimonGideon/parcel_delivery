class UserSerializer
  def initialize(user)
    @user = user
  end

  def as_json(*_args)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      created_at: user.created_at.iso8601
    }
  end

  private

  attr_reader :user
end
