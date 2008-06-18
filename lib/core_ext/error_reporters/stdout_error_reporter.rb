module Background #:nodoc:
  # Reports error on $stdout.
  class StdoutErrorReporter
    # Prints the exception's error message on $stdout.
    def self.report(error)
      puts error.message
    end
  end
end
