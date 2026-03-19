require "test_helper"

class Biscuit::HelperTest < ActionView::TestCase
  include Biscuit::BiscuitHelper

  # Stub the cookies method to return a simple hash-like object
  def cookies
    @cookies ||= HashWithIndifferentAccess.new
  end

  teardown do
    @cookies = nil
    Biscuit.reset_configuration!
  end

  test "biscuit_allowed? returns true for :necessary with no cookie" do
    assert_equal true, biscuit_allowed?(:necessary)
  end

  test "biscuit_allowed? returns false for :analytics with no cookie" do
    assert_equal false, biscuit_allowed?(:analytics)
  end

  test "biscuit_allowed? returns true for :analytics when consent cookie grants it" do
    @cookies = HashWithIndifferentAccess.new(
      "biscuit_consent" => {
        "v"            => 1,
        "consented_at" => "2026-03-19T10:00:00Z",
        "categories"   => { "necessary" => true, "analytics" => true }
      }.to_json
    )
    assert_equal true, biscuit_allowed?(:analytics)
  end

  test "biscuit_banner renders the banner partial" do
    html = biscuit_banner
    assert_match "biscuit-banner", html
    assert_match "data-controller=\"biscuit\"", html
  end
end
