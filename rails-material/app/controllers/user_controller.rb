class UserController < ApplicationController
	def show
		@user = User.find(params[:id])
	end
	def captures
		captures = current_user.captures
		captures = captures.collect do |k|
			midi = k.tags.split(" ").select{|item| item.starts_with?("midi")}
			
			if midi.length == 0
				nil
			else
				pos = midi[0].split(":")[1].split("-")
				pad = pos[0].to_i
				slot = pos[1].to_i
				{pad: pad, slot: slot, video: k.file.webm.url}
			end
			
		end
		render :json => captures
	end
end

