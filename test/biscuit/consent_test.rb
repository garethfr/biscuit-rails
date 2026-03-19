require "test_helper"

class Biscuit::ConsentTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # Biscuit::Consent.parse
  # ---------------------------------------------------------------------------

  test "parse returns nil for nil input" do
    assert_nil Biscuit::Consent.parse(nil)
  end

  test "parse returns nil for an empty string" do
    assert_nil Biscuit::Consent.parse("")
  end

  test "parse returns nil for invalid JSON" do
    assert_nil Biscuit::Consent.parse("not json at all")
  end

  test "parse returns nil if version field is missing" do
    json = { "categories" => { "necessary" => true } }.to_json
    assert_nil Biscuit::Consent.parse(json)
  end

  test "parse returns nil if version field is wrong" do
    json = { "v" => 99, "categories" => { "necessary" => true } }.to_json
    assert_nil Biscuit::Consent.parse(json)
  end

  test "parse returns the parsed hash for a valid cookie string" do
    json = {
      "v"            => 1,
      "consented_at" => "2026-03-19T10:00:00Z",
      "categories"   => { "necessary" => true, "analytics" => false }
    }.to_json
    result = Biscuit::Consent.parse(json)
    assert_instance_of Hash, result
    assert_equal 1, result["v"]
    assert_equal({ "necessary" => true, "analytics" => false }, result["categories"])
  end

  # ---------------------------------------------------------------------------
  # Biscuit::Consent.build_value
  # ---------------------------------------------------------------------------

  test "build_value always sets necessary to true" do
    result = Biscuit::Consent.build_value({ "necessary" => false, "analytics" => true })
    assert_equal true, result["categories"]["necessary"]
  end

  test "build_value sets v to 1" do
    result = Biscuit::Consent.build_value({})
    assert_equal 1, result["v"]
  end

  test "build_value sets consented_at to a UTC ISO8601 string" do
    result = Biscuit::Consent.build_value({})
    # Should be a UTC ISO8601 timestamp like "2026-03-19T10:00:00Z"
    assert_match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/, result["consented_at"])
  end

  test "build_value coerces string true to boolean true" do
    result = Biscuit::Consent.build_value({ "analytics" => "true" })
    assert_equal true, result["categories"]["analytics"]
  end

  test "build_value coerces string false to boolean false" do
    result = Biscuit::Consent.build_value({ "analytics" => "false" })
    assert_equal false, result["categories"]["analytics"]
  end

  # ---------------------------------------------------------------------------
  # Instance methods
  # ---------------------------------------------------------------------------

  test "given? returns false when cookie is absent" do
    cookies = { "biscuit_consent" => nil }
    consent = Biscuit::Consent.new(cookies)
    assert_equal false, consent.given?
  end

  test "given? returns true when a valid cookie is present" do
    raw = valid_cookie_json(analytics: true)
    cookies = { "biscuit_consent" => raw }
    consent = Biscuit::Consent.new(cookies)
    assert_equal true, consent.given?
  end

  test "allowed?(:necessary) returns true regardless of cookie state" do
    cookies = { "biscuit_consent" => nil }
    consent = Biscuit::Consent.new(cookies)
    assert_equal true, consent.allowed?(:necessary)
  end

  test "allowed?(:analytics) returns false when no cookie is present" do
    cookies = { "biscuit_consent" => nil }
    consent = Biscuit::Consent.new(cookies)
    assert_equal false, consent.allowed?(:analytics)
  end

  test "allowed?(:analytics) returns true when cookie has analytics: true" do
    raw = valid_cookie_json(analytics: true)
    cookies = { "biscuit_consent" => raw }
    consent = Biscuit::Consent.new(cookies)
    assert_equal true, consent.allowed?(:analytics)
  end

  test "allowed?(:analytics) returns false when cookie has analytics: false" do
    raw = valid_cookie_json(analytics: false)
    cookies = { "biscuit_consent" => raw }
    consent = Biscuit::Consent.new(cookies)
    assert_equal false, consent.allowed?(:analytics)
  end

  private

  def valid_cookie_json(**categories)
    {
      "v"            => 1,
      "consented_at" => "2026-03-19T10:00:00Z",
      "categories"   => { "necessary" => true }.merge(categories.transform_keys(&:to_s))
    }.to_json
  end
end
