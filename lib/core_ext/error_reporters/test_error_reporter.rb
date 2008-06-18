module Background #:nodoc:
  # This class is used for reporting errors in a test environment.
  class TestErrorReporter
    # Stores the last error
    cattr_accessor :last_error
    # Does not actually report any error, but stores it in last_error.
    def self.report(error)
      self.last_error = error
    end
  end
end
