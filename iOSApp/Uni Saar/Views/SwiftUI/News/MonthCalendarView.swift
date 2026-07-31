import SwiftUI

/// Native month grid replacing FSCalendar
struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var visibleMonth: Date
    let eventCount: (Date) -> Int

    @ScaledMetric private var dayHeight: CGFloat = 36
    @ScaledMetric private var dotSize: CGFloat = 5

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 8) {
            header
            weekdayRow
            dayGrid
        }
        .tint(Color(.uniTintColor))
        .gesture(pagingSwipe)
    }

    private var header: some View {
        HStack {
            Button {
                page(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .accessibilityLabel(String(localized: "PreviousMonth"))
            Spacer()
            Text(visibleMonth, format: .dateTime.month(.wide).year())
                .font(.headline)
            Spacer()
            Button {
                page(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .accessibilityLabel(String(localized: "NextMonth"))
        }
        .padding(.horizontal, 4)
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(weekDates, id: \.self) { day in
                Text(day, format: .dateTime.weekday(.short))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    private var dayGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
            ForEach(Array(monthCells.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear
                        .frame(height: dayHeight)
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(day)
        let count = eventCount(day)
        return Button {
            selectedDate = day
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    if isSelected, isToday {
                        Circle().fill(.tint)
                    } else if isSelected {
                        Circle().fill(.tint.quaternary)
                    }
                    Text(day, format: .dateTime.day())
                        .font(.callout)
                        .fontWeight(isSelected || isToday ? .semibold : .regular)
                        .foregroundStyle(dayNumberStyle(isSelected: isSelected, isToday: isToday))
                }
                .frame(height: dayHeight)
                eventDots(count: count)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(day, format: .dateTime.weekday(.wide).day().month(.wide)))
        .accessibilityValue(count > 0 ? String(format: String(localized: "EventsCount"), count) : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func dayNumberStyle(isSelected: Bool, isToday: Bool) -> AnyShapeStyle {
        if isSelected, isToday {
            AnyShapeStyle(.white)
        } else if isSelected || isToday {
            AnyShapeStyle(.tint)
        } else {
            AnyShapeStyle(Color(.labelCustomColor))
        }
    }

    private func eventDots(count: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(0 ..< min(count, 3), id: \.self) { _ in
                Circle()
                    .fill(.tint)
                    .frame(width: dotSize, height: dotSize)
            }
        }
        .frame(height: dotSize)
    }

    private var monthCells: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: visibleMonth),
              let dayCount = calendar.range(of: .day, in: .month, for: visibleMonth)?.count else { return [] }
        let firstDay = calendar.startOfDay(for: monthInterval.start)
        let leadingBlanks = (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
        let days = (0 ..< dayCount).compactMap { calendar.date(byAdding: .day, value: $0, to: firstDay) }
        return Array(repeating: nil, count: leadingBlanks) + days
    }

    private var weekDates: [Date] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: visibleMonth) else { return [] }
        return (0 ..< 7).compactMap { calendar.date(byAdding: .day, value: $0, to: week.start) }
    }

    private func page(by value: Int) {
        guard let next = calendar.date(byAdding: .month, value: value, to: visibleMonth) else { return }
        withAnimation(.snappy) {
            visibleMonth = next
        }
    }

    private var pagingSwipe: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                page(by: value.translation.width < 0 ? 1 : -1)
            }
    }
}

#Preview {
    @Previewable @State var selectedDate = Calendar.current.startOfDay(for: Date())
    @Previewable @State var visibleMonth = Calendar.current.dateInterval(of: .month, for: Date())!.start
    MonthCalendarView(selectedDate: $selectedDate, visibleMonth: $visibleMonth) { date in
        Calendar.current.component(.day, from: date) % 4
    }
    .padding()
}
