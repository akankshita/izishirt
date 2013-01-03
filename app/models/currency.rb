class Currency < ActiveRecord::Base
	def self.convert(currency_from, currency_to, amount)
		#c = Currency.new
		#return (amount.to_f * c.exact_currency_rate(currency_from, currency_to).to_f).round(2)
		#conversion = c.main_currency_convert(currency_from, currency_to, amount)

		#puts "C = #{conversion.type}"

		#return conversion
		return amount
	end

	def self.to_cad(amount, from_currency_id)
		begin
			currency = Currency.find(from_currency_id)
		rescue
			currency = nil
		end

		if ! currency
			currency = Currency.find_by_label("CAD")
		end

		ratio = 1.0

		if currency.label == "EUR"
			ratio = 1.35
		elsif currency.label == "GBP"
			ratio = 1.60
		end

		return amount.to_f * ratio
	end
end
