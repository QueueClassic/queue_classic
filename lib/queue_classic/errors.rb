module QC

  class QueueError < StandardError
  end

  # Raised when a database adapter is not found
  class AdapterHandlerNotSpecified < QueueError
  end

  # Raised when a adapter is found but don't have a initialize method
  class AdapterInitializeMethodNotFound < QueueError
  end

end

