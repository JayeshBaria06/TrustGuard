import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), netBalance: "$0.00", owed: "Owed: $0.00", owing: "Owing: $0.00")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), netBalance: "$0.00", owed: "Owed: $0.00", owing: "Owing: $0.00")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Suite name should match the one configured in Xcode and Flutter
        let userDefaults = UserDefaults(suiteName: "group.com.trustguard.trustguard")
        let netBalance = userDefaults?.string(forKey: "widget_net_balance") ?? "$0.00"
        let owed = userDefaults?.string(forKey: "widget_owed") ?? "Owed: $0.00"
        let owing = userDefaults?.string(forKey: "widget_owing") ?? "Owing: $0.00"

        let entry = SimpleEntry(date: Date(), netBalance: netBalance, owed: owed, owing: owing)
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let netBalance: String
    let owed: String
    let owing: String
}

struct BalanceWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TrustGuard")
                .font(.caption2)
                .opacity(0.7)

            Spacer()

            Text(entry.netBalance)
                .font(.title)
                .bold()
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Spacer()

            HStack {
                Text(entry.owed)
                    .font(.system(size: 10))
                    .foregroundColor(Color(red: 185/255, green: 246/255, blue: 202/255))
                Spacer()
                Text(entry.owing)
                    .font(.system(size: 10))
                    .foregroundColor(Color(red: 255/255, green: 218/255, blue: 218/255))
            }
        }
        .padding()
        .background(Color(red: 103/255, green: 80/255, blue: 164/255))
        .foregroundColor(.white)
    }
}

@main
struct BalanceWidget: Widget {
    let kind: String = "BalanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BalanceWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("TrustGuard Balance")
        .description("View your current balances at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
