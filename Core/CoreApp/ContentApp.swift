import Foundation
import UIKit

enum ContentApp: AnyStateApp {
    public struct Helpers {
        let venueRepo: Repository<Venue>
    }

    public static func initialState() -> State {
        State(buttonTapped: 0)
    }

    public enum Input {
        case checkForData
        case selectedVenue(item: Venue)
        case saveVenues(item: [Venue])
    }

    public struct State: Equatable, Codable {
        var buttonTapped: Int = 0
    }

    public enum Effect: Equatable {
        case loadHistoricalEvents
        case saveToRepository(items: [Venue])
    }

    // need to create a new effect to dispatch to another state machine
    public static func handle(event: Input, with state: State, and helpers: Helpers) -> Next<State, Effect> {
        switch event {
        case .checkForData:
            return .with(.loadHistoricalEvents)
        case .selectedVenue(var item):
            item.timeOfDay = Date.now
            return .with(.saveToRepository(items: [item])) // Saves the dated version
        case .saveVenues(let items):
            return .init(state: state, effects: [.saveToRepository(items: items)])
        }
    }

    public static func handle(effect: Effect, with state: State, on app: AnyDispatch<Input, Helpers>) {
        switch effect {
        case .loadHistoricalEvents: 
            break
        case .saveToRepository(let items):
            _ = app.helpers.venueRepo.dispatch(.add(items: items))
        }
    }
}
