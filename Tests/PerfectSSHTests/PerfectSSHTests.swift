import XCTest
@testable import PerfectSSH

class PerfectSSHTests: XCTestCase {

  let host = "bugnut.ca"
  let keypem = "/bugnut.pem"
  let good_pwd = "good_pwd"
  let username = "rocky"

  static var allTests = [
    ("testGoodPass", testGoodPass),
    ("testAccessDenied", testAccessDenied),
    ("testKeyPermFile", testKeyPermFile)
    ]

  override func setUp() {
    SSH.debug = true
  }

  func testKeyPermFile() {
    guard let p = getenv("CURPATH") else {
      XCTFail("MUST APPLY CURPATH VARIABLE")
      return
    }
    let path = String(cString: p) + keypem
    do {
      let ssh = try SSH()
      try ssh.connect(host, username: username, login: SSH.LoginType.PrivateKeyFile(path: path, phrase: nil))
    }catch {
      XCTFail("\(error)")
    }
  }
  
  func testAccessDenied() {
    do {
      let ssh = try SSH()
      try ssh.connect(host)
    }catch(SSH.Exception.AccessDenied(let reason)) {
      XCTAssertNotNil(reason)
    }catch {
      XCTFail("\(error)")
    }
  }

  func testGoodPass() {
    do {
      let ssh = try SSH()
      try ssh.connect(host, username: username, login: SSH.LoginType.Pasword(good_pwd))
    }catch {
      XCTFail("\(error)")
    }
  }
}
