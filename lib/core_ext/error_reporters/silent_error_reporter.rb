module Background #:nodoc:
  # Does not report errors at all.
  class SilentNotificationErrorReporter
    # Suppresses the error message by not reporting anything.
    def self.report(error)
      # do nothing
    end
  end
end
