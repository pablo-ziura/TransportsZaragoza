import XCTest

final class BusJourneyTests: XCTestCase {
    @MainActor
    func testBusArrivalsRetryAndFavorites() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-storage", "--arrival-error-once"]
        app.launch()
        let buses = app.buttons["menu-buses"]
        XCTAssertTrue(buses.waitForExistence(timeout: 15))
        buses.tap()
        app.buttons["bus-line-58"].tap()
        let favorite = app.buttons["favorite-tuzsa-688"]
        XCTAssertTrue(favorite.waitForExistence(timeout: 5))
        favorite.tap()
        let saved = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Quitar de favoritos"), object: favorite)
        XCTAssertEqual(XCTWaiter.wait(for: [saved], timeout: 5), .completed)
        app.buttons["bus-stop-tuzsa-688"].tap()
        XCTAssertTrue(app.staticTexts["No se pudieron consultar los tiempos. Comprueba tu conexión."].waitForExistence(timeout: 5))
        app.buttons["reload-arrivals"].tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "arrival-58").firstMatch.waitForExistence(timeout: 5))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Bus arrivals"
        attachment.lifetime = .keepAlways
        add(attachment)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["menu-favorites"].tap()
        app.segmentedControls.buttons["Autobús"].tap()
        XCTAssertTrue(app.buttons["bus-stop-tuzsa-688"].waitForExistence(timeout: 5))
        app.buttons["bus-stop-tuzsa-688"].tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "arrival-58").firstMatch.waitForExistence(timeout: 5))
    }

    @MainActor
    func testArrivalsWithAccessibilityTextSize() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-storage", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["menu-buses"].waitForExistence(timeout: 15))
        app.buttons["menu-buses"].tap()
        app.buttons["bus-line-58"].tap()
        app.buttons["bus-stop-tuzsa-688"].tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "arrival-58").firstMatch.waitForExistence(timeout: 5))
        app.swipeUp()
        XCTAssertTrue(app.buttons["reload-arrivals"].isHittable)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Bus arrivals large text"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testTramNavigationAndFavoritesRemainAvailable() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-storage"]
        app.launch()
        XCTAssertTrue(app.buttons["Tranvía"].waitForExistence(timeout: 15))
        app.buttons["Tranvía"].tap()
        let favorite = app.buttons["tram-favorite-202"]
        XCTAssertTrue(favorite.waitForExistence(timeout: 5))
        favorite.tap()
        let saved = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Quitar de favoritos"), object: favorite)
        XCTAssertEqual(XCTWaiter.wait(for: [saved], timeout: 5), .completed)
        app.buttons["tram-stop-202"].tap()
        XCTAssertTrue(app.staticTexts["Tiempo estimado: 6 min."].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["menu-favorites"].tap()
        XCTAssertTrue(app.buttons["tram-stop-202"].waitForExistence(timeout: 5))
    }
}
