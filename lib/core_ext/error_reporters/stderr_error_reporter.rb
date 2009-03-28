module Background #:nodoc:
  # Reports error on $stdout.
  class StderrErrorReporter
    # Prints the exception's error message on $stderr.
    def self.report(error)
      $stderr.puts error.message
    end
  end
end
