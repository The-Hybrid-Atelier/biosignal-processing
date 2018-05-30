require 'test_helper'

class CapturesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @capture = captures(:one)
  end

  test "should get index" do
    get captures_url
    assert_response :success
  end

  test "should get new" do
    get new_capture_url
    assert_response :success
  end

  test "should create capture" do
    assert_difference('Capture.count') do
      post captures_url, params: { capture: { file: @capture.file, file_cache: @capture.file_cache, tags: @capture.tags } }
    end

    assert_redirected_to capture_url(Capture.last)
  end

  test "should show capture" do
    get capture_url(@capture)
    assert_response :success
  end

  test "should get edit" do
    get edit_capture_url(@capture)
    assert_response :success
  end

  test "should update capture" do
    patch capture_url(@capture), params: { capture: { file: @capture.file, file_cache: @capture.file_cache, tags: @capture.tags } }
    assert_redirected_to capture_url(@capture)
  end

  test "should destroy capture" do
    assert_difference('Capture.count', -1) do
      delete capture_url(@capture)
    end

    assert_redirected_to captures_url
  end
end
