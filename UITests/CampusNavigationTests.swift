import XCTest

final class CampusNavigationTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testCaptureLightPages() { capturePages(appearance: "light") }
    func testCaptureDarkPages() { capturePages(appearance: "dark") }

    private func capture(_ name: String) {
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = name
        image.lifetime = .keepAlways
        add(image)
    }

    private func capturePages(appearance: String) {
        let app = XCUIApplication()
        app.launchArguments = ["-preview", "today", "-previewAppearance", appearance, "-AppleLanguages", "(zh-Hans)"]
        app.launch()
        XCTAssertTrue(app.staticTexts["今天，也很充实。"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["同和楼 A203"].firstMatch.waitForExistence(timeout: 10))
        capture("today-\(appearance)")
        app.tabBars.buttons["广场"].tap()
        XCTAssertTrue(app.staticTexts["昨天的风"].waitForExistence(timeout: 10))
        capture("plaza-\(appearance)")
        app.tabBars.buttons["消息"].tap()
        XCTAssertTrue(app.staticTexts["有消息，慢慢聊。"].waitForExistence(timeout: 10))
        capture("messages-\(appearance)")
        app.tabBars.buttons["我的"].tap()
        XCTAssertTrue(app.staticTexts["128"].waitForExistence(timeout: 10))
        capture("profile-\(appearance)")
        app.tabBars.buttons["今日"].tap()
        app.buttons["课表"].firstMatch.tap()
        XCTAssertTrue(app.buttons["从教务导入"].waitForExistence(timeout: 10))
        capture("schedule-\(appearance)")
    }
    func testProductionLaunchRequiresLogin() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["用学校账号登录"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.tabBars.buttons["今日"].exists)
        capture("login-light")
    }

    func testCaptureAccessibility() {
        let app = XCUIApplication()
        app.launchArguments = ["-preview", "today", "-AppleLanguages", "(zh-Hans)", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.staticTexts["今天，也很充实。"].waitForExistence(timeout: 20))
        capture("today-accessibility")
    }

    func testTabsAndScheduleUseProductionViews() {
        let app = XCUIApplication()
        app.launchArguments = ["-preview", "today", "-AppleLanguages", "(zh-Hans)"]
        app.launch()
        XCTAssertTrue(app.staticTexts["今天，也很充实。"].waitForExistence(timeout: 10))
        app.buttons["课表"].firstMatch.tap()
        XCTAssertTrue(app.buttons["从教务导入"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["广场"].tap()
        XCTAssertTrue(app.staticTexts["下课，聊两句。"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["发布动态"].exists)
        app.buttons["发布动态"].tap()
        XCTAssertTrue(app.navigationBars["发帖"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["消息"].tap()
        XCTAssertTrue(app.buttons["好友与聊天, 2"].exists || app.staticTexts["好友与聊天"].exists)
        app.tabBars.buttons["我的"].tap()
        XCTAssertTrue(app.staticTexts["在泥工，留个窝。"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["128"].waitForExistence(timeout: 5))
    }
}
