require "rails_helper"

RSpec.describe Users::User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "requires an email" do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("El email no puede estar vacío.")
    end

    it "requires a name" do
      user = build(:user, name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("El nombre no puede estar vacío.")
    end

    it "rejects an invalid email format" do
      user = build(:user, email: "not-an-email")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("El formato del email no es válido.")
    end

    it "enforces maximum length on email (255)" do
      user = build(:user, email: "#{"a" * 244}@example.com")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("El email es demasiado largo (máximo 255 caracteres).")
    end

    it "enforces maximum length on name (100)" do
      user = build(:user, name: "a" * 101)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("El nombre es demasiado largo (máximo 100 caracteres).")
    end

    it "enforces unique email (case insensitive)" do
      create(:user, email: "taken@example.com")
      duplicate = build(:user, email: "TAKEN@example.com")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include("Ese email ya está registrado.")
    end

    it "normalizes email to lowercase before saving" do
      user = create(:user, email: "MixedCase@Example.com")
      expect(user.email).to eq("mixedcase@example.com")
    end
  end

  describe "authentication (has_secure_password)" do
    it "stores a password digest, not the plain password" do
      user = create(:user, password: "secret123", password_confirmation: "secret123")
      expect(user.password_digest).to be_present
      expect(user.password_digest).not_to eq("secret123")
    end

    it "authenticates with the correct password" do
      user = create(:user, password: "secret123", password_confirmation: "secret123")
      expect(user.authenticate("secret123")).to eq(user)
    end

    it "rejects an incorrect password" do
      user = create(:user, password: "secret123", password_confirmation: "secret123")
      expect(user.authenticate("wrong")).to be(false)
    end
  end

  describe "role" do
    it "defaults to customer" do
      expect(build(:user).role).to eq("customer")
    end

    it "supports admin" do
      expect(build(:user, role: :admin)).to be_admin
    end
  end

  describe "communications consent" do
    it "defaults to false" do
      expect(build(:user).communications_consent).to be(false)
    end
  end
end
