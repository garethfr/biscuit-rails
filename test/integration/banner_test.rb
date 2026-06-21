require "test_helper"

class BannerIntegrationTest < ActionDispatch::IntegrationTest
  # ---------------------------------------------------------------------------
  # HTML structure tests
  # ---------------------------------------------------------------------------

  test "banner is visible on first visit with no cookie present" do
    get "/"
    assert_response :success
    assert_select ".biscuit-banner"
    assert_select "[data-controller='biscuit']"
  end

  test "banner has already-consented value false when no cookie" do
    get "/"
    assert_select "[data-biscuit-already-consented-value='false']"
  end

  test "manage preferences button is present in the banner" do
    get "/"
    assert_match "biscuit#togglePreferences", response.body
  end

  test "preferences panel is present and hidden by default" do
    get "/"
    assert_select ".biscuit-preferences"
    assert_match 'data-biscuit-target="preferencesPanel"', response.body
  end

  test "accept all button has correct data-action" do
    get "/"
    assert_match "biscuit#acceptAll", response.body
  end

  test "reject all button has correct data-action" do
    get "/"
    assert_match "biscuit#rejectAll", response.body
  end

  test "manage link is present and hidden by default" do
    get "/"
    assert_select ".biscuit-manage-link[hidden]"
  end

  test "necessary category checkbox is disabled and checked" do
    get "/"
    assert_select "input[disabled][checked]"
  end

  # ---------------------------------------------------------------------------
  # HTTP endpoint tests
  # ---------------------------------------------------------------------------

  test "POST /biscuit/consent with valid payload and CSRF token returns ok: true" do
    get "/"
    token = css_select('meta[name="csrf-token"]').first&.attr("content")

    post biscuit.consent_path,
         params: { categories: { analytics: "true", marketing: "false" } },
         headers: { "X-CSRF-Token" => token }

    assert_response :success
    assert_equal({ "ok" => true }, response.parsed_body)
  end

  test "POST /biscuit/consent sets the consent cookie" do
    get "/"
    token = css_select('meta[name="csrf-token"]').first&.attr("content")

    post biscuit.consent_path,
         params: { categories: { analytics: "true", marketing: "false" } },
         headers: { "X-CSRF-Token" => token }

    cookie_value = JSON.parse(cookies["biscuit_consent"])
    assert_equal 1, cookie_value["v"]
    assert_equal true, cookie_value["categories"]["analytics"]
    assert_equal false, cookie_value["categories"]["marketing"]
    assert_equal true, cookie_value["categories"]["necessary"]
  end

  test "POST /biscuit/consent without CSRF token returns 422" do
    ActionController::Base.allow_forgery_protection = true
    post biscuit.consent_path,
         params: { categories: { analytics: "true" } }
    assert_response 422
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  test "DELETE /biscuit/consent clears the consent cookie and returns ok: true" do
    get "/"
    token = css_select('meta[name="csrf-token"]').first&.attr("content")

    post biscuit.consent_path,
         params: { categories: { analytics: "true" } },
         headers: { "X-CSRF-Token" => token }
    assert cookies["biscuit_consent"].present?

    delete biscuit.consent_path,
           headers: { "X-CSRF-Token" => token }

    assert_response :success
    assert_equal({ "ok" => true }, response.parsed_body)
    assert_predicate cookies["biscuit_consent"], :blank?
  end

  test "after consent is given and page is reloaded banner shows already-consented true" do
    get "/"
    token = css_select('meta[name="csrf-token"]').first&.attr("content")

    post biscuit.consent_path,
         params: { categories: { analytics: "true", marketing: "true" } },
         headers: { "X-CSRF-Token" => token }

    get "/"
    assert_select "[data-biscuit-already-consented-value='true']"
  end

  test "reject all sets all non-required categories to false" do
    get "/"
    token = css_select('meta[name="csrf-token"]').first&.attr("content")

    post biscuit.consent_path,
         params: { categories: { analytics: "false", marketing: "false" } },
         headers: { "X-CSRF-Token" => token }

    cookie_value = JSON.parse(cookies["biscuit_consent"])
    assert_equal false, cookie_value["categories"]["analytics"]
    assert_equal false, cookie_value["categories"]["marketing"]
    assert_equal true,  cookie_value["categories"]["necessary"]
  end

  test "consent cookie always forces necessary to true even if submitted as false" do
    get "/"
    token = css_select('meta[name="csrf-token"]').first&.attr("content")

    post biscuit.consent_path,
         params: { categories: { necessary: "false", analytics: "false" } },
         headers: { "X-CSRF-Token" => token }

    cookie_value = JSON.parse(cookies["biscuit_consent"])
    assert_equal true, cookie_value["categories"]["necessary"]
  end
end
