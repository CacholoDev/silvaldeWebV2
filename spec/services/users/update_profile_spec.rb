require "rails_helper"

RSpec.describe Users::UpdateProfile do
  let(:user) { create(:user) }

  it "updates the user with valid attributes" do
    described_class.call(user, name: "Nuevo", email: "nuevo@example.com")

    expect(user.reload.name).to eq("Nuevo")
    expect(user.reload.email).to eq("nuevo@example.com")
  end

  it "returns the user with errors when invalid" do
    result = described_class.call(user, name: "")

    expect(result).to eq(user)
    expect(result.errors[:name]).to be_present
  end
end
