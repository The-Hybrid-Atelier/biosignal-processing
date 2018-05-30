require 'test_helper'

class StudyControllerTest < ActionDispatch::IntegrationTest
  test "should get log" do
    get study_log_url
    assert_response :success
  end

end
