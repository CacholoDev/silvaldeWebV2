require "rails_helper"

RSpec.describe Auth::PurgeExpiredJob do
  it "purges expired sessions and stale reset tokens" do
    expired = create(:session)
    expired.update_column(:expires_at, 1.minute.ago)

    described_class.perform_now

    expect(Auth::Session.exists?(expired.id)).to be(false)
  end

  it "runs quietly when there is nothing to purge" do
    expect { described_class.perform_now }.not_to raise_error
  end
end
