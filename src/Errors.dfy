// S6: Error types and Result — spec: allium.md §Error Types
module Errors {

  // S6-E01: error variants (spec: allium.md §Error Types)
  datatype DogStatsDError =
    | ErrNoClient               // operation on nil or closed client
    | ErrorInputChannelFull     // worker input channel full (channel mode)
    | ErrorSenderChannelFull    // sender queue full
    | MessageTooLongError       // single metric exceeds maxBytesPerPayload

  // S6-E02: human-readable error description
  function ErrorMessage(e: DogStatsDError): string
  {
    match e
    case ErrNoClient             => "operation on nil or closed client"
    case ErrorInputChannelFull   => "worker input channel full"
    case ErrorSenderChannelFull  => "sender channel full"
    case MessageTooLongError     => "metric exceeds max bytes per payload"
  }

  // S6-E03: generic Result type (inline — stdlib not configured)
  datatype Result<T> = Ok(value: T) | Err(error: DogStatsDError)

}
