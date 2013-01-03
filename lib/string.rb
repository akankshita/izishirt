class String
  def append_time(prepend)
    time = File.exists?(prepend+self) ? "?#{File.new(prepend+self).mtime.to_i}" : ""
    "#{self}#{time}"
  end
end 
