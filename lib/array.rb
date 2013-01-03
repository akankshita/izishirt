class Array
  def uniq_by
    seen = {}
    select{ |x|
      v = yield(x)
      !seen[v] && (seen[v]=true)
    }
  end
end 
