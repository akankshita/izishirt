class PaymentType < ActiveRecord::Base
	has_many :localized_payment_types

	def local_name(language_id)
		begin
			return localized_payment_types.find_by_language_id(language_id).name
		rescue
			return "N/A"
		end
	end
end
