require 'test_helper'

class SensingControllerTest < ActionDispatch::IntegrationTest
  test "should get codes" do
    get sensing_codes_url
    assert_response :success
  end

end
