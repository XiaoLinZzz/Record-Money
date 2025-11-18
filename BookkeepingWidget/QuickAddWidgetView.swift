//
//  QuickAddWidgetView.swift
//  BookkeepingWidget
//
//  快速记账 Widget 视图
//

import SwiftUI
import WidgetKit

struct QuickAddWidgetView: View {
    let entry: QuickAddEntry

    var body: some View {
        Link(destination: URL(string: "autobookkeeping://add")!) {
            VStack(spacing: 12) {
                // 图标
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)

                    Image(systemName: "plus")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }

                // 文字
                Text("快速记账")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
    }
}
