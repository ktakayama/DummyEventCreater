//
//  StringExtension.swift
//  DummyEventCreater
//
//  Created by Kyosuke Takayama on 2018/07/09.
//  Copyright © 2018年 Kyosuke Takayama. All rights reserved.
//

import Foundation
import EventKit

extension String {

    var recurrenceFrequency: EKRecurrenceFrequency {
        switch self {
        case "daily":
            return .daily
        case "weekly":
            return .weekly
        case "monthly":
            return .monthly
        case "yearly":
            return .yearly
        default:
            return .weekly
        }
    }

}
