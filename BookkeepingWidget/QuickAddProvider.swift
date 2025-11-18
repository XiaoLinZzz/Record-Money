//
//  QuickAddProvider.swift
//  BookkeepingWidget
//
//  快速记账 Timeline Provider
//

import WidgetKit
import SwiftUI

// MARK: - Quick Add Entry

struct QuickAddEntry: TimelineEntry {
    let date: Date
}

// MARK: - Quick Add Provider

struct QuickAddProvider: TimelineProvider {

    // MARK: - Placeholder

    func placeholder(in context: Context) -> QuickAddEntry {
        QuickAddEntry(date: Date())
    }

    // MARK: - Snapshot

    func getSnapshot(in context: Context, completion: @escaping (QuickAddEntry) -> Void) {
        let entry = QuickAddEntry(date: Date())
        completion(entry)
    }

    // MARK: - Timeline

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickAddEntry>) -> Void) {
        let entry = QuickAddEntry(date: Date())

        // 静态 Widget，每天更新一次即可
        let nextUpdate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }
}
