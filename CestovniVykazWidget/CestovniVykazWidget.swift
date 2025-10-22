import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), totalHours: 8.5, totalKilometers: 120.0, totalEarnings: 2500.0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let dataManager = WidgetDataManager.shared
        let entry = SimpleEntry(
            date: Date(),
            totalHours: dataManager.getTotalHours(),
            totalKilometers: dataManager.getTotalKilometers(),
            totalEarnings: dataManager.getTotalEarnings()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let dataManager = WidgetDataManager.shared
        let currentDate = Date()
        
        // Create entry with current data
        let entry = SimpleEntry(
            date: currentDate,
            totalHours: dataManager.getTotalHours(),
            totalKilometers: dataManager.getTotalKilometers(),
            totalEarnings: dataManager.getTotalEarnings()
        )
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let totalHours: Double
    let totalKilometers: Double
    let totalEarnings: Double
}

struct CestovniVykazWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.blue)
                
                Text("Cestovní Výkaz")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            // Stats
            HStack(spacing: 8) {
                WidgetStatCard(
                    title: "Hodiny",
                    value: String(format: "%.1f", entry.totalHours),
                    icon: "clock.fill",
                    color: .blue
                )
                
                WidgetStatCard(
                    title: "Km",
                    value: String(format: "%.0f", entry.totalKilometers),
                    icon: "car.fill",
                    color: .green
                )
                
                WidgetStatCard(
                    title: "Kč",
                    value: String(format: "%.0f", entry.totalEarnings),
                    icon: "fuelpump.fill",
                    color: .orange
                )
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
    }
}

struct WidgetStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.12))
        )
    }
}

struct CestovniVykazWidget: Widget {
    let kind: String = "CestovniVykazWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                CestovniVykazWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                CestovniVykazWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Cestovní Výkaz")
        .description("Zobrazuje statistiky za aktuální měsíc")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    CestovniVykazWidget()
} timeline: {
    SimpleEntry(date: .now, totalHours: 8.5, totalKilometers: 120.0, totalEarnings: 2500.0)
    SimpleEntry(date: .now, totalHours: 12.3, totalKilometers: 180.0, totalEarnings: 3200.0)
}
