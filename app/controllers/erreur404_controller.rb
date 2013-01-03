class Erreur404Controller < ApplicationController

  def index


	if params[:erreur] == ["back"] || params[:erreur] == ["front"] || params[:erreur].include?("playerProductInstall") || params[:erreur].include?("rockyourwear") || 
		params["erreur"] == ["images"] || 
		params["erreur"] == ["left"] || 
		params["erreur"] == ["right"] || 
		params["erreur"] == ["izishirtfiles"]

		redirect_to "/", :status => :moved_permanently
		return
	end

    render :status => "404 Not Found", :layout=>"izishirt_2011"
  end

	def check_is_swf?(errors)
		errors.each do |err|
			if err.index(".swf") && err.index(".swf") == (err.length - 4)
				return true
			end
		end

		return false
	end

end
