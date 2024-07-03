//
//  ABIItems.swift
//  Core
//
//  Created by LL on 6/24/22.
//

import Foundation


struct Venue: Storable, Equatable {
    let title: String
    let address: String
    let latitude: Double?
    let longitude: Double?
    var timeOfDay: Date?
    var id: String {
        title +
        address +
        String(describing: latitude) +
        String(describing: longitude) +
        String(describing: timeOfDay) // does a SHA
    }

    enum IndexedFields: IndexableKeys {
        case title, address, latitude, longitude, timeOfDay
    }
}
