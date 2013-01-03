
require 'net/https'
require 'uri'
require 'rexml/document'

class Xml
	@map

	@@indent_chars = "  "

	def initialize
		@map = {}
	end

	def Xml.make_attrs(class_name,keys)
		keys.each do |key|
			class_name.class_eval "
				def #{key.downcase}
					@map['#{key}']
				end

				def #{key.downcase}=(value)
					@map['#{key}'] = value
				end"
		end
	end

	def to_xml_low(element_name,keys,indent)

		xml = indent + "<" + element_name +">" 
		child_indent = indent + @@indent_chars

		keys.each do |key|
			if @map[key]
				if @map[key].instance_of?(String)
					xml += "\n" + child_indent + "<" + key + ">" +
											@map[key] + "</" + key +">" 
				elsif @map[key].instance_of?(Array)
					@map[key].each do |element|
						xml += "\n" + element.to_xml(child_indent)
					end
				else
					xml += "\n" + @map[key].to_xml(child_indent)
				end
			end
		end

		xml += "\n" + indent + "</" + element_name +">"
	end
end

class HttpsPoster


	def HttpsPoster.post(mpg_request, env = "production")

		uri_s = (env == "production") ? "https://www3.moneris.com" : "https://esqa.moneris.com"

		uri = URI.parse(uri_s) 
		

		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE

		puts "Sending:\n#{mpg_request.to_xml}"

		response = RespMod::Response.new
		
		http.start {
			http.request_post("/gateway2/servlet/MpgRequest",mpg_request.to_xml) {|res|
				response.from_xml(res.body)
			}
		}
		
		return response
	end
end

############ Request Classes ###################
module ReqMod
class Request < Xml
	@@keys = ["store_id","api_token","purchase","track2_purchase","track2_preauth","track2_completion","cavv_purchase","refund","ind_refund","preauth","cavv_preauth","forcepost","completion","purchasecorrection","batchclose","opentotals","idebit_purchase","idebit_refund","purchase_reversal"]
 	make_attrs(Request,@@keys)

	def to_xml(indent="")
		to_xml_low("request",@@keys,indent)
	end
end

class Purchase < Xml
	@@keys = ["order_id","cust_id","amount","pan","expdate","crypt_type","cust_info","recur","avs_info","cvd_info"]
 	make_attrs(Purchase,@@keys)

	def to_xml(indent="")
		to_xml_low("purchase",@@keys,indent)
	end
end

class Preauth < Xml
	@@keys = ["order_id","cust_id","amount","pan","expdate","crypt_type","cust_info","avs_info","cvd_info"]
 	make_attrs(Preauth,@@keys)

	def to_xml(indent="")
		to_xml_low("preauth",@@keys,indent)
	end
end

class Track2Purchase < Xml
	@@keys = ["order_id","cust_id","amount","track2","ecom","pan","expdate","cust_info"]
 	make_attrs(Track2Purchase,@@keys)

	def to_xml(indent="")
		to_xml_low("track2_purchase",@@keys,indent)
	end
end

class Track2Preauth < Xml
	@@keys = ["order_id","cust_id","amount","track2","ecom","pan","expdate","cust_info"]
 	make_attrs(Track2Preauth,@@keys)

	def to_xml(indent="")
		to_xml_low("track2_preauth",@@keys,indent)
	end
end

class Track2Completion < Xml
	@@keys = ["order_id","comp_amount","txn_number","ecom"]
 	make_attrs(Track2Completion,@@keys)

	def to_xml(indent="")
		to_xml_low("track2_completion",@@keys,indent)
	end
end

class CavvPurchase < Xml
	@@keys = ["order_id","cust_id","amount","pan","expdate","cavv","cust_info","avs_info","cvd_info"]
 	make_attrs(CavvPurchase,@@keys)

	def to_xml(indent="")
		to_xml_low("cavv_purchase",@@keys,indent)
	end
end

class CavvPreauth < Xml
	@@keys = ["order_id","cust_id","amount","pan","expdate","cavv","cust_info","avs_info","cvd_info"]
 	make_attrs(CavvPreauth,@@keys)

	def to_xml(indent="")
		to_xml_low("cavv_preauth",@@keys,indent)
	end
end

class Refund < Xml
	@@keys = ["order_id","amount","txn_number","crypt_type"]
 	make_attrs(Refund,@@keys)

	def to_xml(indent="")
		to_xml_low("refund",@@keys,indent)
	end
end

class IndRefund < Xml
	@@keys = ["order_id","cust_id","amount","pan","expdate","crypt_type"]
 	make_attrs(IndRefund,@@keys)

	def to_xml(indent="")
		to_xml_low("ind_refund",@@keys,indent)
	end
end

class Forcepost < Xml
	@@keys = ["order_id","cust_id","amount","pan","expdate","auth_code","crypt_type","cust_info"]
 	make_attrs(Forcepost,@@keys)

	def to_xml(indent="")
		to_xml_low("forcepost",@@keys,indent)
	end
end

class Completion < Xml
	@@keys = ["order_id","comp_amount","txn_number","crypt_type"]
 	make_attrs(Completion,@@keys)

	def to_xml(indent="")
		to_xml_low("completion",@@keys,indent)
	end
end

class Purchasecorrection < Xml
	@@keys = ["order_id","txn_number","crypt_type"]
 	make_attrs(Purchasecorrection,@@keys)

	def to_xml(indent="")
		to_xml_low("purchasecorrection",@@keys,indent)
	end
end

class IdebitPurchase < Xml
	@@keys = ["order_id", "amount", "idebit_track2"]
 	make_attrs(IdebitPurchase,@@keys)

	def to_xml(indent="")
		to_xml_low("idebit_purchase",@@keys,indent)
	end
end

class IdebitRefund < Xml
	@@keys = ["order_id", "amount", "txn_number"]
 	make_attrs(IdebitRefund,@@keys)

	def to_xml(indent="")
		to_xml_low("idebit_refund",@@keys,indent)
	end
end

class PurchaseReversal < Xml
	@@keys = ["order_id", "amount"]
 	make_attrs(PurchaseReversal,@@keys)

	def to_xml(indent="")
		to_xml_low("purchase_reversal",@@keys,indent)
	end
end

class Batchclose < Xml
	@@keys = ["ecr_number"]
 	make_attrs(Batchclose,@@keys)

	def to_xml(indent="")
		to_xml_low("batchclose",@@keys,indent)
	end
end

class Opentotals < Xml
	@@keys = ["ecr_number"]
 	make_attrs(Opentotals,@@keys)

	def to_xml(indent="")
		to_xml_low("opentotals",@@keys,indent)
	end
end

class CustInfo < Xml
	@@keys = ["billing","shipping","email","instructions","item"]
 	make_attrs(CustInfo,@@keys)

	def to_xml(indent="")
		to_xml_low("cust_info",@@keys,indent)
	end
end

class RecurInfo < Xml
	@@keys = ["recur_unit","start_now","start_date","num_recurs","period","recur_amount"]
 	make_attrs(RecurInfo,@@keys)

	def to_xml(indent="")
		to_xml_low("recur",@@keys,indent)
	end
end

class CVDInfo < Xml
	@@keys = ["cvd_indicator","cvd_value"]
 	make_attrs(CVDInfo,@@keys)

	def to_xml(indent="")
		to_xml_low("cvd_info",@@keys,indent)
	end
end

class AVSInfo < Xml
	@@keys = ["avs_street_number","avs_street_name","avs_zipcode"]
 	make_attrs(AVSInfo,@@keys)

	def to_xml(indent="")
		to_xml_low("avs_info",@@keys,indent)
	end
end

class Billing < Xml
	@@keys = ["first_name","last_name","company_name","address","city","province","postal_code","country","phone_number","fax","tax1","tax2","tax3","shipping_cost"]
 	make_attrs(Billing,@@keys)

	def to_xml(indent="")
		to_xml_low("billing",@@keys,indent)
	end
end

class Shipping < Xml
	@@keys = ["first_name","last_name","company_name","address","city","province","postal_code","country","phone_number","fax","tax1","tax2","tax3","shipping_cost"]
 	make_attrs(Shipping,@@keys)

	def to_xml(indent="")
		to_xml_low("shipping",@@keys,indent)
	end
end

class Item < Xml
	@@keys = ["name","quantity","product_code","extended_amount"]
 	make_attrs(Item,@@keys)

	def to_xml(indent="")
			to_xml_low("item",@@keys,indent)
	end
end
end
############## Response Classes ###################
module RespMod
class Response < Xml
        @@keys = ["receipt"]
        make_attrs(Response,@@keys)

        def to_xml(indent="")
                to_xml_low("response",@@keys,indent)
        end
				
				def from_xml(xml)
					doc = REXML::Document.new(xml)
					
					#doc.write($stdout, 1)
					
					receipt = RespMod::Receipt.new
					receipt.from_xml(doc.root().get_elements("receipt")[0])
					@map['receipt'] = receipt
					
				end
end

class Receipt < Xml
        @@keys = ["ReceiptId","ReferenceNum","ResponseCode","ISO","AuthCode","TransTime","TransDate","TransType","Complete","Message","TransAmount","CardType","TransID","TimedOut","BankTotals","Ticket","RecurSuccess","AvsResultCode","CvdResultCode"]
        make_attrs(Receipt,@@keys)

        def to_xml(indent="")
                to_xml_low("receipt",@@keys,indent)
        end
				
				def from_xml(element)
				
					@map['ReceiptId'] = element.get_elements("ReceiptId")[0].get_text.value
					@map['ReferenceNum'] = element.get_elements("ReferenceNum")[0].get_text.value
					@map['ResponseCode'] = element.get_elements("ResponseCode")[0].get_text.value
					@map['ISO'] = element.get_elements("ISO")[0].get_text.value
					
					begin
						# added by martin.
						@map['AuthCode'] = element.get_elements("AuthCode")[0].get_text.value
					rescue
						@map['AuthCode'] = "N/A"
					end
					@map['TransTime'] = element.get_elements("TransTime")[0].get_text.value
					@map['TransDate'] = element.get_elements("TransDate")[0].get_text.value
					@map['TransType'] = element.get_elements("TransType")[0].get_text.value
					@map['Complete'] = element.get_elements("Complete")[0].get_text.value
					@map['Message'] = element.get_elements("Message")[0].get_text.value
					@map['TransAmount'] = element.get_elements("TransAmount")[0].get_text.value
					@map['CardType'] = element.get_elements("CardType")[0].get_text.value
					@map['TransID'] = element.get_elements("TransID")[0].get_text.value
					@map['TimedOut'] = element.get_elements("TimedOut")[0].get_text.value
					@map['Ticket'] = element.get_elements("Ticket")[0].get_text.value

					if element.get_elements("RecurSuccess")[0] != nil
						@map['RecurSuccess'] = element.get_elements("RecurSuccess")[0].get_text.value
					end
				
					if element.get_elements("AvsResultCode")[0] != nil
						@map['AvsResultCode'] = element.get_elements("AvsResultCode")[0].get_text.value
					end
					
					if element.get_elements("CvdResultCode")[0] != nil
						@map['CvdResultCode'] = element.get_elements("CvdResultCode")[0].get_text.value
					end
					
					banktotals = RespMod::Banktotals.new
					banktotals.from_xml(element.get_elements("BankTotals")[0])
					@map['BankTotals'] = banktotals

				end
end

class Banktotals < Xml
        @@keys = ["ECR"]
        make_attrs(Banktotals,@@keys)

        def to_xml(indent="")
          to_xml_low("BankTotals",@@keys,indent)
        end
        
        def from_xml(element)
        
          ecr = RespMod::Ecr.new
          ecr.from_xml(element.get_elements("ECR")[0])
          @map['ECR'] = ecr
        
        end
end

class Ecr < Xml
        @@keys = ["term_id","closed","Card"]
        make_attrs(Ecr,@@keys)

        def to_xml(indent="")
					to_xml_low("ECR",@@keys,indent)
        end
        
        def from_xml(element)
					
					if element != nil
	
						@map['term_id'] = element.get_elements("term_id")[0].get_text.value
						@map['closed'] = element.get_elements("closed")[0].get_text.value
					
						cards = Array.new
					
						card1 = RespMod::Card.new
						card1.from_xml(element.get_elements("Card")[0])
										
						card2 = RespMod::Card.new
						card2.from_xml(element.get_elements("Card")[1])
					
					
						card3 = RespMod::Card.new
						card3.from_xml(element.get_elements("Card")[2])
					
  					cards << card1 << card2 << card3
					
						@map['Card'] = cards
					end
        end
end

class Card < Xml
        @@keys = ["CardType","Purchase","Refund","Correction"]
        make_attrs(Card,@@keys)

        def to_xml(indent="")
                to_xml_low("Card",@@keys,indent)
        end
				
				def from_xml(element)
					
					if element != nil
						purchase = RespMod::Purchase.new
						purchase.from_xml(element.get_elements("Purchase")[0])
						@map['Purchase'] = purchase
				
						refund = RespMod::Refund.new
						refund.from_xml(element.get_elements("Refund")[0])
						@map['Refund'] = refund

						correction = RespMod::Correction.new
						correction.from_xml(element.get_elements("Correction")[0])
						@map['Correction'] = correction
					
					
						if element.get_elements("CardType")[0] !=nil
							@map['CardType'] = element.get_elements("CardType")[0].get_text.value
						end
					end
				end
				
end

class Purchase < Xml
        @@keys = ["Count","Amount"]
        make_attrs(Purchase,@@keys)

        def to_xml(indent="")
                to_xml_low("Purchase",@@keys,indent)
        end
				
				def from_xml(element)
					if element !=nil
						@map['Count'] = element.get_elements("Count")[0].get_text.value
						@map['Amount'] = element.get_elements("Amount")[0].get_text.value
					end
				end
end

class Refund < Xml
        @@keys = ["Count","Amount"]
        make_attrs(Refund,@@keys)

        def to_xml(indent="")
                to_xml_low("Refund",@@keys,indent)
        end
				
				def from_xml(element)
					if element !=nil
						@map['Count'] = element.get_elements("Count")[0].get_text.value
						@map['Amount'] = element.get_elements("Amount")[0].get_text.value
					end
				end
end

class Correction < Xml
        @@keys = ["Count","Amount"]
        make_attrs(Correction,@@keys)

        def to_xml(indent="")
                to_xml_low("Correction",@@keys,indent)
        end
				
				def from_xml(element)
					if element !=nil
						@map['Count'] = element.get_elements("Count")[0].get_text.value
						@map['Amount'] = element.get_elements("Amount")[0].get_text.value
					end
				end
end
end
