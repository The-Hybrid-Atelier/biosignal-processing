class SensingController < ApplicationController
  def codes
  	@sounds = get_sounds()
  	render :layout => "wide_app"
  end
end
