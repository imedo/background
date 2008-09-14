class MockController #:nodoc:
  def controller_name
    "Background"
  end
  def action_name
    "do"
  end
end

class MockRequest #:nodoc:
  attr_accessor :format
  
  def initialize(message, options = {})
    @message = message
    options.each do |k, v|
      self.instance_variable_set(:"@#{k}", v)
    end
  end

  def env
    {}
  end
  def protocol
    "none"
  end
  def request_uri
    "none"
  end
  def parameters
    @message || "nil message. this does not happen (TM)."
  end
  def session
    "none"
  end
end

module Background #:nodoc:
  # Notifies developers about errors per e-mail.
  class ExceptionNotificationErrorReporter
    # This method uses the exception notification plugin to deliver the exception
    # together with a backtrace to the developers. Refer to the ExceptionNotification
    # documentation for details.
    def self.report(error)
      ExceptionNotifier.deliver_exception_notification(error, MockController.new, MockRequest.new(error.message), {})
    end
  end
end
