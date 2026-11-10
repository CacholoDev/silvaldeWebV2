require "rubocop"
require "rubocop/rspec/support"
require_relative "../../../../lib/rubocop/cop/silvalde"

RSpec.describe RuboCop::Cop::Silvalde::NoActiveRecordInControllers, :config do
  include RuboCop::RSpec::ExpectOffense

  it "flags a query on a model constant" do
    expect_offense(<<~RUBY)
      @product = Catalog::Product.find_by!(slug: params[:slug])
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Controllers must not query the database (`Catalog::Product.find_by!`). Move the read to `<Context>::Search` or the write to a use-case service.
    RUBY
  end

  it "flags authenticate_by" do
    expect_offense(<<~RUBY)
      Users::User.authenticate_by(email: email, password: password)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Controllers must not query the database (`Users::User.authenticate_by`). Move the read to `<Context>::Search` or the write to a use-case service.
    RUBY
  end

  it "allows the Search services and the use-case services" do
    expect_no_offenses(<<~RUBY)
      @product = Catalog::Search.product_by_slug!(params[:slug])
      Search.find(params[:id])
      Carts::AddItem.call(cart: current_cart, variant: variant)
    RUBY
  end

  it "allows building a blank record for a form" do
    expect_no_offenses("@user = Users::User.new")
  end
end
