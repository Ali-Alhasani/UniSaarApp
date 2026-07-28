import SwiftUI

/// Replaces `EventCalanderViewController` + FSCalendar.
struct EventCalendarView: View {
    @State private var viewModel = EventViewModel()
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var visibleMonth = Self.firstOfMonth(Date())
    @State private var activeAlert: SingleButtonAlert?
    /// Rebuilt once per load so the grid's ~35 cells don't each re-filter the month.
    @State private var eventCounts: [Date: Int] = [:]
    @State private var isWide = false
    /// 7 day columns × ~56pt comfortable tap target; scales with Dynamic Type
    /// like the grid cells themselves, so the cap grows with the content.
    @ScaledMetric(relativeTo: .callout) private var calendarMaxWidth: CGFloat = 400

    var body: some View {
        layoutView
            .onGeometryChange(for: Bool.self) { $0.size.width > $0.size.height } action: { isWide = $0 }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(String(localized: "EventsTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .singleButtonAlert($activeAlert)
            // `id:` reruns on month paging and cancels the superseded request in flight.
            .task(id: visibleMonth) {
                viewModel.onAlert = { activeAlert = $0 }
                viewModel.onRetry = { Task { await loadVisibleMonth() } }
                await loadVisibleMonth()
            }
            .onChange(of: selectedDate) {
                viewModel.getDayEvents(day: selectedDate)
            }
    }

    private var layoutView: some View {
        let layout = isWide
            ? AnyLayout(HStackLayout(alignment: .top, spacing: 0))
            : AnyLayout(VStackLayout(spacing: 0))
        return layout {
            monthCalendar
                .frame(maxWidth: calendarMaxWidth)
            eventList
        }
    }

    private var monthCalendar: some View {
        MonthCalendarView(selectedDate: $selectedDate, visibleMonth: $visibleMonth) { eventCounts[$0] ?? 0 }
            .padding(.horizontal)
            .padding(.vertical, 8)
    }

    @ViewBuilder
    private var eventList: some View {
        if viewModel.showLoadingIndicator, viewModel.selectedDateEvents.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if dayEvents.isEmpty {
                        ContentUnavailableView {
                            Image(systemName: "calendar.badge.exclamationmark")
                        } description: {
                            Text(String(localized: "EmptyEvents"))
                        }
                        .padding(.top, 24)
                    } else {
                        ForEach(dayEvents) { cellViewModel in
                            card(for: cellViewModel)
                        }
                    }
                }
            }
            .contentMargins(16.0, for: .scrollContent)
            .refreshable {
                await loadVisibleMonth()
            }
        }
    }

    private var dayEvents: [NewsFeedCellViewModel] {
        viewModel.selectedDateEvents.compactMap {
            if case let .normal(cellViewModel) = $0 {
                cellViewModel
            } else {
                nil
            }
        }
    }

    private func card(for cellViewModel: NewsFeedCellViewModel) -> some View {
        NavigationLink(value: cellViewModel.newsItem) {
            NewsItemRow(viewModel: cellViewModel)
        }
        .buttonStyle(.plain)
    }

    private func loadVisibleMonth() async {
        let components = Calendar.current.dateComponents([.month, .year], from: visibleMonth)
        await viewModel.loadGetEvents(month: String(components.month ?? 1), year: String(components.year ?? 1970))
        eventCounts = countEvents()
    }

    private func countEvents() -> [Date: Int] {
        viewModel.eventCells.reduce(into: [:]) { counts, cell in
            if case let .normal(event) = cell, let day = viewModel.convertDate(strDate: event.newsDate) {
                counts[day, default: 0] += 1
            }
        }
    }

    private static func firstOfMonth(_ date: Date) -> Date {
        Calendar.current.dateInterval(of: .month, for: date)?.start ?? Calendar.current.startOfDay(for: date)
    }
}

#Preview {
    NavigationStack {
        EventCalendarView()
    }
}
