//
//  MainViewModelTests.swift
//  BleepleTests
//
//  Created by Corné on 8/17/24.
//

@testable import Bleeple
import XCTest

final class MainViewModelTests: XCTestCase {
    func testUndoRedo() throws {
        let viewModel = MainView.ViewModel.shared
            
        // Check initial state
        XCTAssert(viewModel.events.isEmpty, "Initial events should be empty")
        
        // Edge case: Undo with no events
        viewModel.undo()
        XCTAssert(viewModel.events.isEmpty, "Should remain empty after undo with no events")
            
        // Edge case: Redo with no events
        viewModel.redo()
        XCTAssert(viewModel.events.isEmpty, "Should remain empty after redo with no events")

        // Add first event
        let event1 = Event(pitch: 0, start: 0, track: 0)
        viewModel.addEvent(event1)
        XCTAssert(viewModel.events.count == 1, "Should contain one event after adding")
        XCTAssert(viewModel.events.first == event1, "The first event should be event1")
            
        // Add second event
        let event2 = Event(pitch: 1, start: 1, track: 0)
        viewModel.addEvent(event2)
        XCTAssert(viewModel.events.count == 2, "Should contain two events after adding")
        XCTAssert(viewModel.events.last == event2, "The last event should be event2")
            
        // Undo last event
        viewModel.undo()
        XCTAssert(viewModel.events.count == 1, "Should contain one event after undo")
        XCTAssert(viewModel.events.first == event1, "The first event should still be event1 after undo")
            
        // Undo first event
        viewModel.undo()
        XCTAssert(viewModel.events.isEmpty, "Should be empty after undoing all events")
            
        // Redo first event
        viewModel.redo()
        XCTAssert(viewModel.events.count == 1, "Should contain one event after redo")
        XCTAssert(viewModel.events.first == event1, "The first event should be event1 after redo")
            
        // Redo second event
        viewModel.redo()
        XCTAssert(viewModel.events.count == 2, "Should contain two events after redo")
        XCTAssert(viewModel.events.last == event2, "The last event should be event2 after redo")
            
        // Clear all events
        viewModel.clear()
        XCTAssert(viewModel.events.isEmpty, "Should be empty after clearing all events")
            
        // Undo clear
        viewModel.undo()
        XCTAssert(viewModel.events.count == 2, "Should contain two events after undoing clear")
            
        // Redo clear
        viewModel.redo()
        XCTAssert(viewModel.events.isEmpty, "Should be empty after redoing clear")
    }
}
