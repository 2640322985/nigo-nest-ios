import XCTest

final class CampusNavigationTests: XCTestCase {
    func testProductionLaunchRequiresLogin() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["用学校账号登录"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.tabBars.buttons["今日"].exists)
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
