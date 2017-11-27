import SSHApi
import Dispatch
import Foundation

public class SSH {
  public static var debug = false
  private var connected = false

  public enum Exception: Error {
    case InvalidOption
    case OptionFailure(String)
    case GeneralFailure
    case ConnectionFailure(String)
    case AccessDenied(String)
  }

  public enum LoginType {
    case Pasword(String)
    case PrivateKeyFile(path: String, phrase: String?)
    case None
  }
  public func connect(_ host: String, port: Int = 22, username: String? = nil, login: LoginType = .None) throws {

    try setOption(SSH_OPTIONS_HOST, host)
    try setOption(SSH_OPTIONS_PORT, port)
    if let usr = username {
      try setOption(SSH_OPTIONS_USER, usr)
    }

    guard SSH_OK == ssh_connect(session) else {
      throw Exception.ConnectionFailure(lastError)
    }

    connected = true
    var auth = Int32(0)
    switch login {
    case .Pasword(let pwd):
      auth = ssh_userauth_password(session, nil, pwd)
      break
    case .PrivateKeyFile(let (keypath, phrase)):
      auth = ssh_userauth_privatekey_file(session, nil, keypath, phrase)
    default:
      auth = ssh_userauth_none(session, nil)
    }
    switch ssh_auth_e(auth) {
    case SSH_AUTH_ERROR : throw Exception.AccessDenied(lastError)
    case SSH_AUTH_DENIED: throw Exception.AccessDenied("Try another method")
    case SSH_AUTH_PARTIAL: throw Exception.AccessDenied("Further method required")
    case SSH_AUTH_AGAIN: throw Exception.AccessDenied("Call this again")
    case SSH_AUTH_SUCCESS: return
    default:
      throw Exception.AccessDenied("Unknown")
    }
  }

  public func setOption(_ option: ssh_options_e, _ to: Any) throws {
    let ret: Int32
    if to is String, let string = to as? String {
      ret = string.withCString { p in
        ssh_options_set(session, option, p)
      }
    } else if to is Int, let int = to as? Int {
      var i = int
      ret = ssh_options_set(session, option, &i)
    } else {
      throw Exception.InvalidOption
    }
    guard ret == 0 else {
      throw Exception.OptionFailure(lastError)
    }
  }

  public var lastError: String {
    return String(cString: ssh_get_error(UnsafeMutableRawPointer(session)))
  }

  let session: OpaquePointer

  public init() throws {
    guard let sess = ssh_new() else {
      throw Exception.GeneralFailure
    }
    session = sess
    if SSH.debug {
      try setOption(SSH_OPTIONS_LOG_VERBOSITY, SSH_LOG_PROTOCOL)
    }
  }

  deinit {
    if connected {
      ssh_disconnect(session)
    }
    ssh_free(session)
  }
}
