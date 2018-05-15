class MaterialController < ApplicationController
  def annotator
  end
  def vision
  	@sounds = get_sounds()
  	render :layout => "wide_app"
  end
  def conversion
    @sounds = get_sounds()
    render :layout => "wide_app"
  end

  def setup
    @sounds = get_sounds()
    render :layout => "wide_app"
  end

  def video_feed
    @sounds = get_sounds()
    render :layout => "wide_app"
  end
  def websocket_test
    render :layout => "wide_app"
  end
  def designer
    render :layout => "wide_app"
  end

  def camera
    @sounds = get_sounds()
    render :layout => "wide_app"
  end
end
