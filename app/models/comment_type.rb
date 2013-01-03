class CommentType < ActiveRecord::Base
	has_many :comments
	has_many :localized_comment_types

	def local_name(language_id)
		begin
			return localized_comment_types.find_by_language_id(language_id).name
		rescue
			return "N/A"
		end
	end
end
