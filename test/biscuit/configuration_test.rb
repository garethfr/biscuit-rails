require "test_helper"

class Biscuit::ConfigurationTest < ActiveSupport::TestCase
  setup do
    Biscuit.reset_configuration!
  end

  teardown do
    Biscuit.reset_configuration!
  end

  test "default cookie_name is biscuit_consent" do
    assert_equal "biscuit_consent", Biscuit.configuration.cookie_name
  end

  test "default categories include :necessary with required: true" do
    assert Biscuit.configuration.categories.key?(:necessary)
    assert_equal true, Biscuit.configuration.categories[:necessary][:required]
  end

  test "default position is :bottom" do
    assert_equal :bottom, Biscuit.configuration.position
  end

  test "configure block overrides cookie_expires_days" do
    Biscuit.configure { |c| c.cookie_expires_days = 180 }
    assert_equal 180, Biscuit.configuration.cookie_expires_days
  end

  test "custom categories hash is stored correctly" do
    custom = {
      necessary:   { required: true },
      preferences: { required: false }
    }
    Biscuit.configure { |c| c.categories = custom }
    assert_equal custom, Biscuit.configuration.categories
  end

  test "reset_configuration! restores all defaults" do
    Biscuit.configure do |c|
      c.cookie_name         = "custom_cookie"
      c.cookie_expires_days = 30
      c.position            = :top
      c.privacy_policy_url  = "/privacy"
    end

    Biscuit.reset_configuration!

    assert_equal "biscuit_consent", Biscuit.configuration.cookie_name
    assert_equal 365, Biscuit.configuration.cookie_expires_days
    assert_equal :bottom, Biscuit.configuration.position
    assert_equal "#", Biscuit.configuration.privacy_policy_url
  end

  test "default cookie_expires_days is 365" do
    assert_equal 365, Biscuit.configuration.cookie_expires_days
  end

  test "default privacy_policy_url is #" do
    assert_equal "#", Biscuit.configuration.privacy_policy_url
  end

  test "default cookie_same_site is Lax" do
    assert_equal "Lax", Biscuit.configuration.cookie_same_site
  end

  test "default cookie_domain is nil" do
    assert_nil Biscuit.configuration.cookie_domain
  end

  test "default cookie_path is /" do
    assert_equal "/", Biscuit.configuration.cookie_path
  end
end
