require "rails_helper"

# Rails ships the generic validation messages only in English. Every one of
# them must exist in Spanish too, or a validation without a model-specific
# message shows "Translation missing" to the customer.
RSpec.describe "Validation messages in Spanish and Galician" do
  def keys_for(scope, locale)
    I18n.t(scope, locale: locale).keys
  end

  %i[es gl].each do |locale|
    it "translates every generic validation message into #{locale}" do
      missing = keys_for("errors.messages", :en) - keys_for("errors.messages", locale)

      expect(missing).to be_empty, "faltan en #{locale}.errors.messages: #{missing.join(", ")}"
    end

    it "translates the Active Record exception messages into #{locale}" do
      missing = keys_for("activerecord.errors.messages", :en) - keys_for("activerecord.errors.messages", locale)

      expect(missing).to be_empty, "faltan en #{locale}.activerecord.errors.messages: #{missing.join(", ")}"
    end
  end

  it "names the attribute in Spanish in a generic message" do
    cart = Carts::Cart.new
    cart.errors.add(:user, :blank)

    expect(cart.errors.full_messages.first).to eq("Cuenta no puede estar vacío.")
  end

  it "has a Spanish, Galician and English name for every attribute of the domain models" do
    models = [ Users::User, Catalog::Category, Catalog::Product, Catalog::Variant, Carts::Cart, Carts::CartItem, Orders::Order ]
    skipped = %w[id created_at updated_at password_digest]

    missing = models.flat_map do |model|
      (model.column_names - skipped).flat_map do |column|
        attribute = column.delete_suffix("_id")
        %i[es gl en].filter_map do |locale|
          key = "activerecord.attributes.#{model.model_name.i18n_key}.#{attribute}"
          "#{locale}.#{key}" unless I18n.exists?(key, locale)
        end
      end
    end

    expect(missing).to be_empty, "faltan: #{missing.join(", ")}"
  end
end
