class NotebookController < ApplicationController
  def guide
  	@sounds = get_sounds()
  	render :layout => "wide_app"
  end
  def joule
    @sounds = get_sounds()
    render :layout => "wide_app"
  end
  def capture
    @sounds = get_sounds()
    render :layout => "wide_app"
  end
  def print
    @sounds = get_sounds()
    render :layout => "wide_app"
  end
  def debugging
  	@sounds = get_sounds()
  	render :layout => "wide_app"
  end
  def save_file 
    if params["svg"]
    	File.open("public/test.svg", 'w') do |file| 
        file.write(params["svg"])
      end
    	respond_to do |format|
        format.html {render :json => "/test.svg", status: :created}
        format.json {render :json => "/test.svg", status: :created}
      end
    else
      File.open("public/test.png", 'wb') do |file| 
        data = params["png"]
        file.write(Base64.decode64(data['data:image/png;base64,'.length .. -1]))
      end      
      
      respond_to do |format|
        format.html {render :json => "/test.png", status: :created}
        format.json {render :json => "/test.png", status: :created}
      end
    end
  end
end
