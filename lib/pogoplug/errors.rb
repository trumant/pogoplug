module PogoPlug

  class ServiceError < StandardError
    attr_reader :response
    def initialize( response )
      super("Failed to process request #{response.status} - #{response.headers.inspect} - #{response.body}")
      @response = response
    end
  end

  ClientError = Class.new(ServiceError)
  ClientTimeoutError = Class.new(ServiceError)
  ServerError = Class.new(ServiceError)
  InvalidArgumentError = Class.new(ServiceError)
  OutOfRangeError = Class.new(ServiceError)
  NotImplementedError = Class.new(ServiceError)
  AuthenticationError = Class.new(ServiceError)
  TimeoutError = Class.new(ServiceError)
  TemporaryFailureError = Class.new(ServiceError)
  DuplicateNameError = Class.new(ServiceError)
  NoSuchUserError = Class.new(ServiceError)
  NoSuchDeviceError = Class.new(ServiceError)
  NoSuchServiceError = Class.new(ServiceError)
  NoSuchFilenameError = Class.new(ServiceError)
  InsufficientPermissionsError = Class.new(ServiceError)
  NotAvailableError = Class.new(ServiceError)
  NotFoundError = Class.new(ServiceError)
  StorageOfflineError = Class.new(ServiceError)
  UserExistsError = Class.new(ServiceError)
  UserNotValidatingError = Class.new(ServiceError)
  NameTooLongError = Class.new(ServiceError)
  PasswordNotSetError = Class.new(ServiceError)
  ServiceExpiredError = Class.new(ServiceError)
  InsufficientSpaceError = Class.new(ServiceError)
  UnsupportedError = Class.new(ServiceError)
  ProvisionFailureError = Class.new(ServiceError)
  NotProvisionedError = Class.new(ServiceError)
  InvalidNameError = Class.new(ServiceError)
  LimitReachedError = Class.new(ServiceError)
  InvalidTokenError = Class.new(ServiceError)
  TrialNotAllowedError = Class.new(ServiceError)
  CopyrightDeniedError = Class.new(ServiceError)

  ApiUrlNotAvailable = Class.new(StandardError)
  DirectoriesCanNotBeDownloaded = Class.new(StandardError)

  ERRORS = {
    400 => ClientError,
    500 => ServerError,
    600 => InvalidArgumentError,
    601 => OutOfRangeError,
    602 => NotImplementedError,
    606 => AuthenticationError,
    607 => ClientTimeoutError,
    608 => TemporaryFailureError,
    800 => NoSuchUserError,
    801 => NoSuchDeviceError,
    802 => NoSuchServiceError,
    804 => NotFoundError,
    805 => InsufficientPermissionsError,
    806 => NotAvailableError,
    807 => StorageOfflineError,
    808 => DuplicateNameError,
    809 => NoSuchFilenameError,
    810 => UserExistsError,
    811 => UserNotValidatingError,
    812 => NameTooLongError,
    813 => PasswordNotSetError,
    815 => ServiceExpiredError,
    817 => InsufficientSpaceError,
    818 => UnsupportedError,
    819 => ProvisionFailureError,
    820 => NotProvisionedError,
    822 => InvalidNameError,
    825 => LimitReachedError,
    826 => InvalidTokenError,
    831 => TrialNotAllowedError,
    832 => CopyrightDeniedError,
  }

end