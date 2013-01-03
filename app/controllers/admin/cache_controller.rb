class Admin::CacheController < Administration

	def index
		@cache_actions = {"clear_daily_html" => "Clear daily cache", 
			"clear_week_html" => "Clear week cache", 
			"clear_category_cache" => "Clear category cache", 
			"clear_result_tag_cache" => "Clear design tags cache", 
			"clear_marketplace_cache" => "Clear marketplace lists cache", 
			"clear_marketplace_shop_cache" => "Clear marketplace shop cache", 
			"clear_create_tshirt_cache" => "Clear create tshirt (flash) cache", 
			"clear_design_info_cache" => "Clear design details page cache",
			"clear_izishirt_2011_cache" => "Clear homepage cache",
			"clear_local_cache" => "Clear local pages"}
	end

	def exec_cmd
		begin
			cache_type = params[:cmd]

			cmd = "rake cache:#{cache_type} RAILS_ENV=#{RAILS_ENV}"

			system cmd
		rescue
		end

		redirect_to :action => "index"
	end
end
