//
//  StatusProvider.swift
//  Sonar
//
//  Created by NHSX on 4/27/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum Status: Equatable {
    case blue, amber, red
}

protocol StatusProviding {
    var status: Status { get }
    var amberExpiryDate: Date? { get }
}

class StatusProvider: StatusProviding {

    var status: Status {
        switch (persisting.potentiallyExposed, persisting.selfDiagnosis?.isAffected) {
        case (_, .some(true)):
            return .red
        case (.some(let date), _):
            // This should never happen, but date types, right?
            guard let delta = daysSince(date) else {
                return .blue
            }

            guard delta < 14 else {
                return .blue
            }

            // If we were ever in a red status, we
            // shouldn't go back to amber. In theory,
            // if you were infected and are now
            // asymptomatic, you're now immune and don't
            // need to self-quarantine?
            guard persisting.selfDiagnosis == nil else {
                return .blue
            }

            return .amber
        default:
            return .blue
        }
    }
    
    var amberExpiryDate: Date? {
        switch status {
        case .amber:
            let calendar = Calendar.current
            return calendar.date(byAdding: .day, value: 14, to: persisting.potentiallyExposed!)
        default:
            return nil
        }
    }

    private var currentDate: Date { currentDateProvider() }

    let persisting: Persisting
    let currentDateProvider: () -> Date

    init(
        persisting: Persisting,
        currentDateProvider: @escaping () -> Date = { Date() }
    ) {
        self.persisting = persisting
        self.currentDateProvider = currentDateProvider
    }

    private func daysSince(_ date: Date) -> Int? {
        let dateComponents = Calendar.current.dateComponents(
            [.day],
            from: date,
            to: currentDate
        )
        return dateComponents.day
    }

}
