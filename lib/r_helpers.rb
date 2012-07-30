module RHelpers
  def r_slice(slice)
    if slice.kind_of? Integer
      (slice+1).to_s
    elsif slice.kind_of? Enumerable
      "c(#{slice.map {|i| r_slice(i) }.join(',')})"
    elsif slice.kind_of? Range
      "#{slice.begin+1}:#{slice.end+1}"
    end
  end

  def r_variables(variables=variables)
    if !variables.kind_of?(Enumerable)
      "'#{variables}'"
    elsif variables.length == 1
      "'#{variables.first}'"
    else
      "c(#{variables.map {|v| "'#{v}'"}.join(',')})"
    end
  end
end
