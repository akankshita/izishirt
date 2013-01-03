class SizeType < ActiveRecord::Base
  has_many :models
  has_many :model_sizes

  def default_model_sizes

	good_list = []

	tmp_model_sizes = ModelSize.find_all_by_size_type_id_and_is_default_and_active(id, true, true)

	tmp_model_sizes.each do |tmp_ms|

		already_exists = false

		good_list.each do |gl|
			if tmp_ms.local_name(2) == gl.local_name(2)
				already_exists = true
				break
			end
		end

		if ! already_exists
			Rails.logger.error("ADDING SIZE #{tmp_ms.local_name(2)}")
			good_list << tmp_ms
		end
	end

	return good_list
  end

  def shoes?
    name.include?("Shoes")
  end
end
