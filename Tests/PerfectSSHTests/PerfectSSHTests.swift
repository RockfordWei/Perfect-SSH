import XCTest
@testable import PerfectSSH

class PerfectSSHTests: XCTestCase {

  static var allTests = [
    ("testExample", testExample),
    ("testAccessDeny", testAccessDeny),
    ("testKeyPermFile", testKeyPermFile),
    ]

  func testKeyPermFile() {
    guard let p = getenv("CURPATH") else {
      XCTFail("MUST APPLY CURPATH VARIABLE")
      return
    }
    let path = String(cString: p) + "/bugnut.pem"
    do {
      let ssh = try SSH("bugnut.ca")
      try ssh.login("rocky", privateKeyFile: path)
    } catch SSH.Exception.AccessDenied(let message) {
      print(message)
    }catch {
      XCTFail("\(error)")
    }
  }

  func testAccessDeny() {
    do {
      let ssh = try SSH("bugnut.ca")
      try ssh.login("rocky", password: "wrongpass")
    } catch SSH.Exception.AccessDenied(let message) {
      print(message)
    }catch {
      XCTFail("\(error)")
    }
  }
  func testExample() {
    do {
      let ssh = try SSH("bugnut.ca")
      try ssh.login("rocky", password: "good_pwd")
    }catch {
      XCTFail("\(error)")
    }
  }
}
