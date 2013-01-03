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
