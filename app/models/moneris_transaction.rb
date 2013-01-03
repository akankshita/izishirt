class MonerisTransaction
	def initialize(order_id, user_email, amount, card_number, exp_year, exp_month, ccv, env = "production")
		p = ReqMod::Purchase.new
		a = ReqMod::AVSInfo.new
		c = ReqMod::CVDInfo.new

		exp_year = exp_year[2, 2]

		p.cvd_info = c

		p.cvd_info.cvd_indicator="1"
		p.cvd_info.cvd_value="#{ccv}"

		#p.avs_info = a

		#p.avs_info.avs_zipcode="H2T2A4"


		# our order id
		# an extra random number much be added because if it fails, it will gives dupplicate error.
		p.order_id = "#{order_id}_#{Digest::MD5.hexdigest(Time.now.to_s).to_s[0,5]}_#{rand(10000)}"

		Rails.logger.error("ORDER #{p.order_id}")

		# put EMAIL
		p.cust_id = "#{user_email}"

		p.amount = "#{amount.to_f.round(2)}"
		p.crypt_type = "7"

		# pan = credit cart
		p.pan = "#{card_number}"

		# YYMM
		p.expdate = "#{exp_year}#{exp_month}"

		@request = ReqMod::Request.new

		if env == "production"
			@request.store_id = 'monca11709'

			@request.api_token = 'QDMOiphC83lIUJQuFJnw'
		else
			@request.store_id = 'store1'

			# API TOKEN FOR PRODUCTION: VvvUBMj1tqUkzxw5pXGf
			@request.api_token = 'yesguy'
		end



		@request.purchase = p
		@env = env

		@message = ""
	end


	def execute
		begin
			response = HttpsPoster.post(@request, @env)
			print "\nCard Type = " + response.receipt.cardtype
			print "\nTransaction Amount = " + response.receipt.transamount
			print "\nTxnNumber = " + response.receipt.transid
			print "\nReceiptID = " + response.receipt.receiptid
			print "\nTransaction Type = " + response.receipt.transtype
			print "\nReference Number = " + response.receipt.referencenum
			print "\nResponse Code = " + response.receipt.responsecode
			print "\nISO = " + response.receipt.iso
			print "\nMessage = " + response.receipt.message
			print "\nAuthcode = " + response.receipt.authcode
			print "\nComplete = " + response.receipt.complete
			print "\nTransaction Date = " + response.receipt.transdate
			print "\nTransaction Time = " + response.receipt.transtime
			print "\nTicket = " + response.receipt.ticket
			print "\nTimedOut = " + response.receipt.timedout

			@message = response.receipt.message
			@txn_number = response.receipt.transid
		rescue => e
			@message = "DECLINED, exception caught: #{e}"
			@txn_number = ""
		end

		return valid_transaction, @txn_number
	end

	def success?
		return valid_transaction
	end

	def authorization
		return @txn_number
	end

	def message
		return @message
	end

	private
	def valid_transaction
		begin
			return @message.index("APPROVED") == 0
		rescue
		end

		return false
	end
end
