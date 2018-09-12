class SensingController < ApplicationController
  def codes
  	@sounds = get_sounds()
  	render :layout => "wide_app"
  end
  def codebook
    @sounds = get_sounds()
    render :layout => "wide_app"
  end
  def vid
  	@videos = get_videos()
  	@sounds = []
  	# render :json => @videos
  	render :layout => "wide_app"
  end
end
