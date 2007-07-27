class Array #:nodoc:
  # Method added in Rails rev 7217
  def extract_options!
    last.is_a?(::Hash) ? pop : {}
  end unless defined? Array.new.extract_options!
end
