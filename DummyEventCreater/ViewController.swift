//
//  ViewController.swift
//  DummyEventCreater
//
//  Created by Kyosuke Takayama on 2018/07/05.
//  Copyright © 2018年 Kyosuke Takayama. All rights reserved.
//

import UIKit
import EventKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        EKEventStore().requestAccess(to: .event, completion: { granted, error in
            if(granted) {
                self.insertData()
            }
        })
    }

    func insertData() {
        guard let main = Bundle.main.path(forResource: "DummyData", ofType: nil) else {
            return
        }

        try? FileManager.default.contentsOfDirectory(atPath: main).forEach({ file in
            self.insertFile(csvFile: NSString(string: main).appendingPathComponent(file) as NSString)
        })
    }

    typealias CSV = (
        startDate: String,
        startTime: String,
        endDate: String,
        endTime: String,
        eventName: String,
        location: String,
        url: String,
        memo: String,
        recurrence: String,
        interval: Int?
    )

    func insertFile(csvFile: NSString) {
        guard let data = try? String(contentsOfFile: csvFile as String) else {
            return
        }

        let calendarName = (csvFile.lastPathComponent as NSString).deletingPathExtension

        let store = EKEventStore()
        let calendars = store.calendars(for: .event)

        calendars.filter { cal in cal.title == calendarName }.forEach { c in
            try! store.removeCalendar(c, commit: true)
        }

        let defaultSource = calendars.filter { cal in cal.type != .birthday }.first!.source
        let cal = EKCalendar(for: .event, eventStore: store)
        cal.title = calendarName
        cal.source = defaultSource
        try! store.saveCalendar(cal, commit: true)

        data.split(separator: "\n").forEach({ line in
            print(line)

            let a = line.split(separator: ",", omittingEmptySubsequences: false)
            let csv: CSV = ( String(a[0]), String(a[1]), String(a[2]), String(a[3]), String(a[4]), String(a[5]), String(a[6]), String(a[7]), String(a[8]), Int(a[9]) )

            let event = EKEvent(eventStore: store)
            event.timeZone = TimeZone.current
            event.title = csv.eventName
            event.location = csv.location
            event.notes = csv.memo
            if csv.url.lengthOfBytes(using: .utf8) > 0 {
                event.url = URL(string: csv.url)
            }

            if csv.startTime.lengthOfBytes(using: .utf8) > 0 {
                event.startDate = dateFromString(csv.startDate, hour: csv.startTime)
                event.endDate = dateFromString(csv.endDate, hour: csv.endTime)
            } else {
                event.startDate = dateFromString(csv.startDate, hour: "00:00")
                event.endDate = dateFromString(csv.endDate, hour: "00:00")
                event.isAllDay = true
            }

            if csv.recurrence.lengthOfBytes(using: .utf8) > 0 {
                let rule = EKRecurrenceRule(recurrenceWith: csv.recurrence.recurrenceFrequency, interval: csv.interval ?? 1, end: nil)
                event.addRecurrenceRule(rule)
            }

            event.calendar = cal
            try? store.save(event, span: .thisEvent)
        })
    }

    func dateFromString(_ date: String, hour: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyyy-MM-dd HH:mm:ss", options: 0, locale: nil)
        return formatter.date(from: "\(date) \(hour):00")
    }
}

