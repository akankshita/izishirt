class FileUtil
	def self.is_bigger?(path1, path2)
		begin
			f1 = File.new(path1)
			f2 = File.new(path2)

			return f1.size > f2.size
		rescue
		end
	
		return false
	end
end
