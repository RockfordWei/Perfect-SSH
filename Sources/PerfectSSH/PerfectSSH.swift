import SSHApi
import mininet

public class SSH {
  public enum Exception: Error {
    case GeneralFailure
    case DNSFailure
    case ConnectionFailure
    case SessionInitFailure
    case AccessDenied(String)
    case HandshakeFailure(String)
  }

  public func login(_ userName: String, privateKeyFile: String, privateKeyFilePassword: String? = nil) throws {
    let ret = libssh2_userauth_publickey_fromfile_ex(session, userName, UInt32(userName.count), nil, privateKeyFile, privateKeyFilePassword)
    guard ret == 0 else {
      switch ret {
      case LIBSSH2_ERROR_ALLOC:
        throw Exception.AccessDenied("An internal memory allocation call failed.")
      case LIBSSH2_ERROR_SOCKET_SEND:
        throw Exception.AccessDenied("Unable to send data on socket.")
      case LIBSSH2_ERROR_PASSWORD_EXPIRED:
        throw Exception.AccessDenied("Password Expired")
      case LIBSSH2_ERROR_AUTHENTICATION_FAILED:
        throw Exception.AccessDenied("Access Denied, invalid username/password or public/private key.")
      case LIBSSH2_ERROR_EAGAIN:
        throw Exception.AccessDenied("Operation Blocked.")
      default:
        throw Exception.AccessDenied("Unknown")
      }
    }
  }

  public func login(_ userName: String, password: String) throws {
    let ret = libssh2_userauth_password_ex(session, userName, UInt32(userName.count), password, UInt32(password.count), nil)
    guard ret == 0 else {
      switch ret {
      case LIBSSH2_ERROR_ALLOC:
        throw Exception.AccessDenied("An internal memory allocation call failed.")
      case LIBSSH2_ERROR_SOCKET_SEND:
        throw Exception.AccessDenied("Unable to send data on socket.")
      case LIBSSH2_ERROR_PASSWORD_EXPIRED:
        throw Exception.AccessDenied("Password Expired")
      case LIBSSH2_ERROR_AUTHENTICATION_FAILED:
        throw Exception.AccessDenied("Access Denied, invalid username/password or public/private key.")
      case LIBSSH2_ERROR_EAGAIN:
        throw Exception.AccessDenied("Operation Blocked.")
      default:
        throw Exception.AccessDenied("Unknown")
      }
    }
  }

  let sock: Int32
  let session: OpaquePointer

  public init(_ address: String, port: Int = 22) throws {
    guard let sess = libssh2_session_init_ex(nil, nil, nil, nil) else {
      throw Exception.SessionInitFailure
    }
    session = sess
    sock = connectTo(address, Int32(port))
    switch sock {
    case MININET_INVALID_ADDRESS:
      throw Exception.DNSFailure
    case MININET_CONNECTION_FAILED:
      throw Exception.ConnectionFailure
    default:
      ()
    }
    // connection could be time out, so can try it more
    let now = time(nil)
    var res = LIBSSH2_ERROR_TIMEOUT
    var total = 0
    repeat {
      res = libssh2_session_handshake(session, sock)
      if res == LIBSSH2_ERROR_TIMEOUT {
        usleep(100)
        total += 1
      } else {
        break
      }
    } while (time(nil) - now < 2)
    guard 0 == res else {
      shutDown(sock)
      libssh2_session_free(session)
        switch res {
        case LIBSSH2_ERROR_SOCKET_NONE:
          throw Exception.HandshakeFailure("The socket is invalid.")
        case LIBSSH2_ERROR_BANNER_SEND:
          throw Exception.HandshakeFailure("Unable to send banner to remote host.")
        case LIBSSH2_ERROR_KEX_FAILURE:
          throw Exception.HandshakeFailure("Encryption key exchange with the remote host failed.")
        case LIBSSH2_ERROR_SOCKET_SEND:
          throw Exception.HandshakeFailure("Unable to send data on socket.")
        case LIBSSH2_ERROR_SOCKET_DISCONNECT:
          throw Exception.HandshakeFailure("The socket was disconnected.")
        case LIBSSH2_ERROR_PROTO:
          throw Exception.HandshakeFailure("An invalid SSH protocol response was received on the socket.")
        case LIBSSH2_ERROR_EAGAIN:
          throw Exception.HandshakeFailure("Marked for non-blocking I/O but the call would block.")
        case LIBSSH2_ERROR_TIMEOUT:
          throw Exception.HandshakeFailure("Time out.")
        default:
          throw Exception.HandshakeFailure("Unknown code `\(res)`")
        }
    }
  }

  deinit {
    libssh2_session_disconnect_ex(session, 0, "Swift SSH Session Over", nil)
    libssh2_session_free(session)
    shutDown(sock)
  }
}
