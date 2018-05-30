require 'test_helper'

class MaterialControllerTest < ActionDispatch::IntegrationTest
  test "should get annotator" do
    get material_annotator_url
    assert_response :success
  end

end
