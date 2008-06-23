# Background

module Background #:nodoc:
  # This class is for configuring defaults of the background framework.
  class Config
    # Contains the default background handler that is chosen, if none is specified in the call to Kernel#background.
    @@default_handler = [:in_process, :forget]
    cattr_accessor :default_handler
    
    # Contains the default error reporter.
    @@default_error_reporter = :stdout
    cattr_accessor :default_error_reporter
  end
end
