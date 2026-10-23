require "rails_helper"

RSpec.describe Auth::Authenticate do
  let(:user) { create(:user) }

  it "returns the user with valid credentials" do
    expect(described_class.call(email: user.email, password: "secret123")).to eq(user)
  end

  it "returns nil with an unknown email" do
    expect(described_class.call(email: "unknown@example.com", password: "secret123")).to be_nil
  end

  it "returns nil with a wrong password" do
    expect(described_class.call(email: user.email, password: "wrong")).to be_nil
  end
end
