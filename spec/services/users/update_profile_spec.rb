require "rails_helper"

RSpec.describe Users::UpdateProfile do
  let(:user) { create(:user) }

  it "updates the user with valid attributes" do
    described_class.call(user, name: "Nuevo", email: "nuevo@example.com", current_password: "secret123")

    expect(user.reload.name).to eq("Nuevo")
    expect(user.reload.email).to eq("nuevo@example.com")
  end

  it "returns the user with errors when invalid" do
    result = described_class.call(user, name: "")

    expect(result).to eq(user)
    expect(result.errors[:name]).to be_present
  end

  it "updates the name without asking for the password" do
    described_class.call(user, name: "Solo nombre", email: user.email)

    expect(user.reload.name).to eq("Solo nombre")
  end

  it "refuses an email change without the current password" do
    result = described_class.call(user, name: user.name, email: "robo@example.com")

    expect(result.errors.details[:email]).to include(error: :current_password_invalid)
    expect(user.reload.email).not_to eq("robo@example.com")
  end

  it "refuses an email change with a wrong current password" do
    result = described_class.call(user, email: "robo@example.com", current_password: "wrong")

    expect(result.errors.details[:email]).to include(error: :current_password_invalid)
    expect(user.reload.email).not_to eq("robo@example.com")
  end

  it "treats the same email with other casing as unchanged" do
    described_class.call(user, name: "Otro", email: user.email.upcase)

    expect(user.reload.name).to eq("Otro")
  end
end
