require "rails_helper"

RSpec.describe Auth::Register do
  let(:attributes) { attributes_for(:user) }

  it "returns a persisted user with valid attributes" do
    user = described_class.call(attributes)

    expect(user).to be_a(Users::User)
    expect(user).to be_persisted
  end

  it "returns a non-persisted user with errors when attributes are invalid" do
    user = described_class.call(attributes.merge(email: "invalid"))

    expect(user).not_to be_persisted
    expect(user.errors[:email]).to be_present
  end
end
