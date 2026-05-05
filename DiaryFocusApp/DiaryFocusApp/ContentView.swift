import PhotosUI
import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedDate = Date()
    @State private var showingDiary = false
    @State private var showingSettings = false
    @State private var route: AppRoute = .home
    @State private var moodsByDay: [String: MoodKind] = ContentView.sampleMoods()

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()

                switch route {
                case .home:
                    HomeView(selectedDate: $selectedDate, showingDiary: $showingDiary, moodsByDay: moodsByDay)
                case .bookReview:
                    ReviewView(kind: "Book", symbol: "book.closed")
                case .movieReview:
                    ReviewView(kind: "Movie", symbol: "film")
                case .focus:
                    FocusView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            route = .home
                        } label: {
                            Label("Diary calendar", systemImage: "calendar")
                        }
                        Button {
                            route = .bookReview
                        } label: {
                            Label("Record book review", systemImage: "book.closed")
                        }
                        Button {
                            route = .movieReview
                        } label: {
                            Label("Record movie review", systemImage: "film")
                        }
                        Button {
                            route = .focus
                        } label: {
                            Label("Focus on work/study", systemImage: "timer")
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "house")
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.ink)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title2.weight(.medium))
                            .foregroundStyle(.ink)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingDiary) {
                DiaryEditorView(
                    date: selectedDate,
                    selectedMood: Binding(
                        get: { moodsByDay[Self.dayKey(for: selectedDate)] },
                        set: { newMood in
                            moodsByDay[Self.dayKey(for: selectedDate)] = newMood
                        }
                    )
                )
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .tint(.ink)
    }

    static func dayKey(for date: Date) -> String {
        date.formatted(.iso8601.year().month().day())
    }

    private static func sampleMoods() -> [String: MoodKind] {
        let calendar = Calendar.current
        let now = Date()
        var samples: [String: MoodKind] = [:]
        for (offset, mood) in [(-3, MoodKind.sleepyCloud), (-2, .happyEgg), (-1, .calmCloud), (0, .smilingHeart)] {
            if let date = calendar.date(byAdding: .day, value: offset, to: now) {
                samples[dayKey(for: date)] = mood
            }
        }
        return samples
    }
}

enum AppRoute {
    case home
    case bookReview
    case movieReview
    case focus
}

struct HomeView: View {
    @Binding var selectedDate: Date
    @Binding var showingDiary: Bool
    let moodsByDay: [String: MoodKind]

    private let calendar = Calendar.current
    private let referenceDate = Date()

    var body: some View {
        VStack(spacing: 34) {
            Spacer(minLength: 70)

            VStack(spacing: 6) {
                Text(yearText)
                    .font(.system(size: 28, weight: .regular, design: .rounded))
                Text(monthText)
                    .font(.system(size: 42, weight: .regular, design: .rounded))
            }
            .foregroundStyle(.ink)
            .padding(.bottom, 28)

            CalendarGrid(
                monthDate: referenceDate,
                moodsByDay: moodsByDay,
                selectedDate: $selectedDate,
                showingDiary: $showingDiary
            )

            Spacer()

            Button {
                selectedDate = Date()
                showingDiary = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 34, weight: .regular))
                    .foregroundStyle(.ink)
                    .frame(width: 82, height: 82)
                    .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .ink.opacity(0.06), radius: 18, y: 10)
            }
            .accessibilityLabel("Add diary entry")
            .padding(.bottom, 54)
        }
        .padding(.horizontal, 24)
    }

    private var yearText: String {
        String(calendar.component(.year, from: referenceDate))
    }

    private var monthText: String {
        referenceDate.formatted(.dateTime.month(.wide)).uppercased()
    }
}

struct CalendarGrid: View {
    let monthDate: Date
    let moodsByDay: [String: MoodKind]
    @Binding var selectedDate: Date
    @Binding var showingDiary: Bool

    private let calendar = Calendar.current
    private let columnSpacing: CGFloat = 8
    private let rowSpacing: CGFloat = 28

    var body: some View {
        GeometryReader { proxy in
            let cellWidth: CGFloat = proxy.size.width >= 344 ? 44 : 42

            calendarGrid(cellWidth: cellWidth)
                .frame(width: cellWidth * 7 + columnSpacing * 6)
                .frame(maxWidth: .infinity, alignment: .center)
                .offset(x: -8)
        }
        .frame(height: calendarHeight)
    }

    private func calendarGrid(cellWidth: CGFloat) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: columnSpacing), count: 7), spacing: rowSpacing) {
            ForEach(cells, id: \.id) { cell in
                Group {
                    if let day = cell.day {
                        DayCell(day: day, date: cell.date, mood: moodFor(date: cell.date), width: cellWidth)
                            .onTapGesture {
                                selectedDate = cell.date
                                showingDiary = true
                            }
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
    }

    private func moodFor(date: Date) -> Mood? {
        guard calendar.startOfDay(for: date) <= calendar.startOfDay(for: Date()) else {
            return nil
        }
        return moodsByDay[ContentView.dayKey(for: date)]?.mood
    }

    private var cells: [CalendarCell] {
        guard
            let interval = calendar.dateInterval(of: .month, for: monthDate),
            let dayRange = calendar.range(of: .day, in: .month, for: monthDate)
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: interval.start)
        var result = (1..<firstWeekday).map { CalendarCell(id: "blank-\($0)", day: nil, date: interval.start) }

        for day in dayRange {
            let date = calendar.date(byAdding: .day, value: day - 1, to: interval.start) ?? interval.start
            result.append(CalendarCell(id: "day-\(day)", day: day, date: date))
        }

        return result
    }

    private var calendarHeight: CGFloat {
        let rowCount = CGFloat((cells.count + 6) / 7)
        return rowCount * 44 + max(0, rowCount - 1) * rowSpacing
    }
}

struct CalendarCell {
    let id: String
    let day: Int?
    let date: Date
}

struct DayCell: View {
    let day: Int
    let date: Date
    let mood: Mood?
    let width: CGFloat

    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            if let mood {
                MoodBadge(mood: mood)
                    .frame(width: width, height: width * 0.76)
            } else {
                Text("\(day)")
                    .font(.system(size: 22, weight: .regular, design: .rounded))
                    .foregroundStyle(numberColor)
                    .frame(width: width, height: 44)
            }
        }
        .frame(width: width, height: 44)
        .contentShape(Rectangle())
    }

    private var numberColor: Color {
        let weekday = calendar.component(.weekday, from: date)
        if weekday == 1 { return .peach.opacity(0.86) }
        if weekday == 7 { return .sky.opacity(0.86) }
        return .softGray
    }
}

struct MoodBadge: View {
    let mood: Mood

    var body: some View {
        ZStack {
            mood.shape
                .fill(mood.color.opacity(0.82))
                .overlay(mood.shape.stroke(.white.opacity(0.7), lineWidth: 1))

            FaceView(expression: mood.expression)
                .stroke(.ink.opacity(0.82), style: StrokeStyle(lineWidth: 2.3, lineCap: .round, lineJoin: .round))
                .frame(width: 24, height: 16)
                .offset(y: 1)
        }
    }
}

struct Mood {
    let color: Color
    let shape: AnyShape
    let expression: FaceExpression

    static let sleepyCloud = Mood(color: .softGray, shape: AnyShape(CloudShape()), expression: .sleepy)
    static let happyEgg = Mood(color: .butter, shape: AnyShape(EggShape()), expression: .closedSmile)
    static let calmCloud = Mood(color: .mint, shape: AnyShape(CloudShape()), expression: .calm)
    static let smilingHeart = Mood(color: .blush, shape: AnyShape(HeartBlobShape()), expression: .smile)
}

enum MoodKind: String, CaseIterable, Identifiable {
    case sleepyCloud
    case happyEgg
    case calmCloud
    case smilingHeart
    case softEgg
    case tiredDog
    case goodFlower
    case quietCloud

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sleepyCloud: return "Sleepy"
        case .happyEgg: return "Bright"
        case .calmCloud: return "Calm"
        case .smilingHeart: return "Loved"
        case .softEgg: return "Soft"
        case .tiredDog: return "Tired"
        case .goodFlower: return "Good"
        case .quietCloud: return "Quiet"
        }
    }

    var mood: Mood {
        switch self {
        case .sleepyCloud: return .sleepyCloud
        case .happyEgg: return .happyEgg
        case .calmCloud: return .calmCloud
        case .smilingHeart: return .smilingHeart
        case .softEgg: return Mood(color: .peach.opacity(0.82), shape: AnyShape(EggShape()), expression: .smile)
        case .tiredDog: return Mood(color: Color(red: 0.94, green: 0.79, blue: 0.64), shape: AnyShape(DogBlobShape()), expression: .tired)
        case .goodFlower: return Mood(color: Color(red: 0.82, green: 0.68, blue: 0.91), shape: AnyShape(SoftFlowerShape()), expression: .smile)
        case .quietCloud: return Mood(color: .sky.opacity(0.75), shape: AnyShape(EggShape()), expression: .peace)
        }
    }
}

enum FaceExpression {
    case smile
    case sleepy
    case closedSmile
    case calm
    case tired
    case peace
}

struct FaceView: Shape {
    let expression: FaceExpression

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let leftEye = CGPoint(x: rect.minX + rect.width * 0.28, y: rect.midY - 3)
        let rightEye = CGPoint(x: rect.minX + rect.width * 0.72, y: rect.midY - 3)

        switch expression {
        case .smile, .calm:
            path.addEllipse(in: CGRect(x: leftEye.x - 1.5, y: leftEye.y - 1.5, width: 3, height: 3))
            path.addEllipse(in: CGRect(x: rightEye.x - 1.5, y: rightEye.y - 1.5, width: 3, height: 3))
        case .sleepy:
            path.move(to: CGPoint(x: leftEye.x - 4, y: leftEye.y))
            path.addLine(to: CGPoint(x: leftEye.x + 2, y: leftEye.y - 2))
            path.move(to: CGPoint(x: rightEye.x - 2, y: rightEye.y - 2))
            path.addLine(to: CGPoint(x: rightEye.x + 4, y: rightEye.y))
        case .tired:
            path.move(to: CGPoint(x: leftEye.x - 4, y: leftEye.y - 1))
            path.addQuadCurve(to: CGPoint(x: leftEye.x + 4, y: leftEye.y - 1), control: CGPoint(x: leftEye.x, y: leftEye.y + 4))
            path.move(to: CGPoint(x: rightEye.x - 4, y: rightEye.y - 1))
            path.addQuadCurve(to: CGPoint(x: rightEye.x + 4, y: rightEye.y - 1), control: CGPoint(x: rightEye.x, y: rightEye.y + 4))
        case .peace:
            path.move(to: CGPoint(x: leftEye.x - 4, y: leftEye.y - 1))
            path.addQuadCurve(to: CGPoint(x: leftEye.x + 4, y: leftEye.y - 1), control: CGPoint(x: leftEye.x, y: leftEye.y + 2.5))
            path.move(to: CGPoint(x: rightEye.x - 4, y: rightEye.y - 1))
            path.addQuadCurve(to: CGPoint(x: rightEye.x + 4, y: rightEye.y - 1), control: CGPoint(x: rightEye.x, y: rightEye.y + 2.5))
        case .closedSmile:
            path.move(to: CGPoint(x: leftEye.x - 4, y: leftEye.y - 2))
            path.addQuadCurve(to: CGPoint(x: leftEye.x + 4, y: leftEye.y - 2), control: CGPoint(x: leftEye.x, y: leftEye.y + 3))
            path.move(to: CGPoint(x: rightEye.x - 4, y: rightEye.y - 2))
            path.addQuadCurve(to: CGPoint(x: rightEye.x + 4, y: rightEye.y - 2), control: CGPoint(x: rightEye.x, y: rightEye.y + 3))
        }

        path.move(to: CGPoint(x: rect.midX - 5, y: rect.midY + 4))
        if expression == .tired {
            path.addQuadCurve(to: CGPoint(x: rect.midX + 5, y: rect.midY + 4), control: CGPoint(x: rect.midX, y: rect.midY + 1))
        } else {
            path.addQuadCurve(to: CGPoint(x: rect.midX + 5, y: rect.midY + 4), control: CGPoint(x: rect.midX, y: rect.midY + mouthDepth))
        }
        return path
    }

    private var mouthDepth: CGFloat {
        switch expression {
        case .sleepy: return 1
        case .calm, .peace: return 5
        case .closedSmile, .smile: return 9
        case .tired: return 1
        }
    }
}

struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.15, y: rect.maxY * 0.72))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.minY + rect.height * 0.3), control1: CGPoint(x: rect.minX + 1, y: rect.midY), control2: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.25))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.58, y: rect.minY + rect.height * 0.22), control1: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.minY), control2: CGPoint(x: rect.minX + rect.width * 0.54, y: rect.minY))
        path.addCurve(to: CGPoint(x: rect.maxX - 2, y: rect.maxY * 0.68), control1: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.minY + rect.height * 0.2), control2: CGPoint(x: rect.maxX + 3, y: rect.midY))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.15, y: rect.maxY * 0.72), control1: CGPoint(x: rect.maxX - 10, y: rect.maxY + 2), control2: CGPoint(x: rect.minX + 8, y: rect.maxY + 1))
        return path
    }
}

struct EggShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + 1))
        path.addCurve(to: CGPoint(x: rect.maxX - 3, y: rect.midY + 4), control1: CGPoint(x: rect.maxX - 4, y: rect.minY + 2), control2: CGPoint(x: rect.maxX, y: rect.midY - 5))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY - 1), control1: CGPoint(x: rect.maxX - 4, y: rect.maxY), control2: CGPoint(x: rect.midX + 10, y: rect.maxY + 2))
        path.addCurve(to: CGPoint(x: rect.minX + 3, y: rect.midY + 4), control1: CGPoint(x: rect.midX - 10, y: rect.maxY + 2), control2: CGPoint(x: rect.minX + 4, y: rect.maxY))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY + 1), control1: CGPoint(x: rect.minX, y: rect.midY - 5), control2: CGPoint(x: rect.minX + 4, y: rect.minY + 2))
        return path
    }
}

struct HeartBlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY - 4))
        path.addCurve(to: CGPoint(x: rect.minX + 4, y: rect.midY), control1: CGPoint(x: rect.midX - rect.width * 0.3, y: rect.maxY - 2), control2: CGPoint(x: rect.minX, y: rect.maxY * 0.72))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY + 8), control1: CGPoint(x: rect.minX + 4, y: rect.minY + 6), control2: CGPoint(x: rect.midX - 7, y: rect.minY + 4))
        path.addCurve(to: CGPoint(x: rect.maxX - 4, y: rect.midY), control1: CGPoint(x: rect.midX + 7, y: rect.minY + 4), control2: CGPoint(x: rect.maxX - 4, y: rect.minY + 6))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY - 4), control1: CGPoint(x: rect.maxX, y: rect.maxY * 0.72), control2: CGPoint(x: rect.midX + rect.width * 0.3, y: rect.maxY - 2))
        return path
    }
}

struct DogBlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.minY + rect.height * 0.42))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.17), control1: CGPoint(x: rect.minX + rect.width * 0.23, y: rect.minY + rect.height * 0.19), control2: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.minY + rect.height * 0.14))
        path.addCurve(to: CGPoint(x: rect.maxX - rect.width * 0.2, y: rect.minY + rect.height * 0.42), control1: CGPoint(x: rect.maxX - rect.width * 0.38, y: rect.minY + rect.height * 0.14), control2: CGPoint(x: rect.maxX - rect.width * 0.23, y: rect.minY + rect.height * 0.19))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY - 2), control1: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.15), control2: CGPoint(x: rect.maxX - rect.width * 0.26, y: rect.maxY))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.minY + rect.height * 0.42), control1: CGPoint(x: rect.minX + rect.width * 0.26, y: rect.maxY), control2: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.15))
        return path
    }
}

struct SoftFlowerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let petalSize = min(rect.width, rect.height) * 0.46
        let center = CGPoint(x: rect.midX, y: rect.midY)

        for index in 0..<6 {
            let angle = CGFloat(index) / 6 * .pi * 2
            let petalCenter = CGPoint(
                x: center.x + cos(angle) * rect.width * 0.22,
                y: center.y + sin(angle) * rect.height * 0.18
            )
            path.addEllipse(in: CGRect(x: petalCenter.x - petalSize / 2, y: petalCenter.y - petalSize / 2, width: petalSize, height: petalSize))
        }

        path.addEllipse(in: CGRect(x: center.x - petalSize * 0.42, y: center.y - petalSize * 0.42, width: petalSize * 0.84, height: petalSize * 0.84))
        return path
    }
}

struct AnyShape: Shape {
    private let makePath: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        makePath = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        makePath(rect)
    }
}

struct DiaryEditorView: View {
    let date: Date
    @Binding var selectedMood: MoodKind?

    @Environment(\.dismiss) private var dismiss
    @State private var entryText = ""
    @State private var momentText = ""
    @State private var activeMomentTime: Date?
    @State private var moments: [DiaryMoment] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [Data] = []

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        MoodPicker(selectedMood: $selectedMood)

                        PhotosPicker(selection: $selectedItems, maxSelectionCount: 8, matching: .images) {
                            Label("Add pictures", systemImage: "photo.on.rectangle")
                                .font(.system(.headline, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }

                        if !selectedImages.isEmpty {
                            GeometryReader { proxy in
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(selectedImages.indices, id: \.self) { index in
                                            if index < selectedImages.count, let uiImage = UIImage(data: selectedImages[index]) {
                                                ZStack(alignment: .topTrailing) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: proxy.size.width, height: 240)
                                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                                        .overlay {
                                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                                .stroke(.white.opacity(0.9), lineWidth: 8)
                                                        }

                                                    Button {
                                                        deleteImage(at: index)
                                                    } label: {
                                                        Image(systemName: "xmark")
                                                            .font(.system(size: 13, weight: .bold))
                                                            .foregroundStyle(.ink)
                                                            .frame(width: 30, height: 30)
                                                            .background(.white.opacity(0.82), in: Circle())
                                                    }
                                                    .accessibilityLabel("Delete picture")
                                                    .padding(14)
                                                }
                                                .frame(width: proxy.size.width, height: 240)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(height: 260)
                        }

                        TextEditor(text: $entryText)
                            .font(.system(size: 18, weight: .regular, design: .rounded))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 180)
                            .padding(14)
                            .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(alignment: .topLeading) {
                                if entryText.isEmpty {
                                    Text("Dear today...")
                                        .font(.system(size: 18, design: .rounded))
                                        .foregroundStyle(.softGray)
                                        .padding(.top, 22)
                                        .padding(.leading, 20)
                                        .allowsHitTesting(false)
                                }
                            }

                        TimelineMomentInput(momentText: $momentText, activeTime: $activeMomentTime) {
                            let trimmed = momentText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard let activeMomentTime, !trimmed.isEmpty else { return }
                            moments.append(DiaryMoment(time: activeMomentTime, text: trimmed))
                            self.activeMomentTime = nil
                            momentText = ""
                        }

                        ForEach(moments) { moment in
                            SwipeToDeleteRow {
                                deleteMoment(moment)
                            } content: {
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(spacing: 4) {
                                        Text(moment.time.formatted(date: .omitted, time: .shortened).lowercased())
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundStyle(.ink.opacity(0.7))
                                        Rectangle()
                                            .fill(.mint.opacity(0.55))
                                            .frame(width: 2, minHeight: 44)
                                    }

                                    Text(moment.text)
                                        .font(.system(size: 16, design: .rounded))
                                        .foregroundStyle(.ink)
                                        .padding(.top, 1)

                                    Spacer(minLength: 0)
                                }
                            }
                        }
                    }
                    .padding(22)
                }
            }
            .navigationTitle(date.formatted(.dateTime.month().day()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedItems) { _, newItems in
                Task {
                    selectedImages = await loadImages(from: newItems)
                }
            }
        }
    }

    private func loadImages(from items: [PhotosPickerItem]) async -> [Data] {
        var imageData: [Data] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                imageData.append(data)
            }
        }
        return imageData
    }

    private func deleteImage(at index: Int) {
        guard selectedImages.indices.contains(index) else { return }
        selectedImages.remove(at: index)

        if selectedItems.indices.contains(index) {
            selectedItems.remove(at: index)
        }
    }

    private func deleteMoment(_ moment: DiaryMoment) {
        moments.removeAll { $0.id == moment.id }
    }
}

struct SwipeToDeleteRow<Content: View>: View {
    let deleteAction: () -> Void
    let content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var isDeleteVisible = false

    private let actionWidth: CGFloat = 82

    init(deleteAction: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.deleteAction = deleteAction
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(role: .destructive) {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.88)) {
                    offset = 0
                    isDeleteVisible = false
                }
                deleteAction()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: actionWidth, height: 54)
                    .background(.red.opacity(0.86), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .accessibilityLabel("Delete todo")

            content()
                .padding(.vertical, 4)
                .background(Color.paper)
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 12)
                        .onChanged { value in
                            let base = isDeleteVisible ? -actionWidth : 0
                            offset = min(0, max(-actionWidth, base + value.translation.width))
                        }
                        .onEnded { value in
                            let shouldReveal = offset < -actionWidth * 0.42 || value.predictedEndTranslation.width < -actionWidth
                            withAnimation(.spring(response: 0.24, dampingFraction: 0.88)) {
                                offset = shouldReveal ? -actionWidth : 0
                                isDeleteVisible = shouldReveal
                            }
                        }
                )
        }
        .contentShape(Rectangle())
    }
}

struct MoodPicker: View {
    @Binding var selectedMood: MoodKind?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.ink)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(MoodKind.allCases) { kind in
                        Button {
                            selectedMood = kind
                        } label: {
                            VStack(spacing: 8) {
                                MoodBadge(mood: kind.mood)
                                    .frame(width: 62, height: 46)
                                Text(kind.title)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                            }
                            .foregroundStyle(.ink)
                            .padding(10)
                            .background(
                                selectedMood == kind ? Color.mint.opacity(0.22) : Color.white.opacity(0.55),
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                        }
                    }
                }
            }
        }
    }
}

struct TimelineMomentInput: View {
    @Binding var momentText: String
    @Binding var activeTime: Date?
    let addMoment: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 5) {
                Button {
                    activeTime = Date()
                } label: {
                    Image(systemName: "clock")
                        .font(.title3)
                        .foregroundStyle(.ink)
                        .frame(width: 42, height: 42)
                        .background(.butter.opacity(0.55), in: Circle())
                }
                .accessibilityLabel("Mark current time")

                if let activeTime {
                    Text(activeTime.formatted(date: .omitted, time: .shortened).lowercased())
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.ink.opacity(0.7))
                    Rectangle()
                        .fill(.mint.opacity(0.55))
                        .frame(width: 2, height: 42)
                }
            }

            TextField("What is happening now?", text: $momentText, axis: .vertical)
                .font(.system(size: 16, design: .rounded))
                .lineLimit(2...5)
                .padding(12)
                .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .onSubmit(addMoment)

            Button(action: addMoment) {
                Image(systemName: "checkmark")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.ink, in: Circle())
            }
            .disabled(activeTime == nil || momentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

struct DiaryMoment: Identifiable {
    let id = UUID()
    let time: Date
    let text: String
}

struct FocusView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var backgroundData: Data?
    @State private var focusMinutes = 25.0
    @State private var remainingSeconds = 25 * 60
    @State private var isRunning = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            if let backgroundData, let image = UIImage(data: backgroundData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay(.white.opacity(0.34))
            } else {
                LinearGradient(colors: [.mint.opacity(0.38), .butter.opacity(0.28), .blush.opacity(0.24)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            }

            VStack(spacing: 28) {
                Spacer()

                Text(timeText)
                    .font(.system(size: 74, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.ink)

                VStack(spacing: 18) {
                    HStack {
                        Image(systemName: "clock")
                        Slider(value: $focusMinutes, in: 5...120, step: 5)
                            .tint(.mint)
                        Text("\(Int(focusMinutes))m")
                            .font(.system(.subheadline, design: .rounded).monospacedDigit())
                    }
                    .disabled(isRunning)

                    HStack(spacing: 12) {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Image(systemName: "photo")
                                .frame(width: 52, height: 52)
                                .background(.white.opacity(0.66), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .accessibilityLabel("Choose focus background")

                        Button {
                            if isRunning {
                                isRunning = false
                            } else {
                                remainingSeconds = Int(focusMinutes) * 60
                                isRunning = true
                            }
                        } label: {
                            Label(isRunning ? "Pause" : "Start", systemImage: isRunning ? "pause.fill" : "play.fill")
                                .font(.system(.headline, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(.ink, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(18)
                .background(.white.opacity(0.56), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.horizontal, 22)

                Spacer()
            }
        }
        .onReceive(timer) { _ in
            guard isRunning else { return }
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                isRunning = false
            }
        }
        .onChange(of: focusMinutes) { _, newValue in
            guard !isRunning else { return }
            remainingSeconds = Int(newValue) * 60
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                backgroundData = try? await newItem?.loadTransferable(type: Data.self)
            }
        }
    }

    private var timeText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct ReviewView: View {
    let kind: String
    let symbol: String

    @State private var title = ""
    @State private var notes = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Label("\(kind) review", systemImage: symbol)
                    .font(.system(.largeTitle, design: .rounded))
                    .foregroundStyle(.ink)
                    .padding(.top, 92)

                TextField("\(kind) title", text: $title)
                    .font(.system(size: 18, design: .rounded))
                    .padding(14)
                    .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                TextEditor(text: $notes)
                    .font(.system(size: 18, design: .rounded))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 260)
                    .padding(14)
                    .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(22)
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var darkMode = false
    @State private var notifications = true
    @State private var lockScreen = false
    @State private var fontChoice = "Rounded"
    @State private var language = "English"

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Font", selection: $fontChoice) {
                        Text("Rounded").tag("Rounded")
                        Text("Serif").tag("Serif")
                        Text("Simple").tag("Simple")
                    }
                    Toggle("Notifications", isOn: $notifications)
                    Toggle("Lock screen", isOn: $lockScreen)
                    Toggle("Dark mode", isOn: $darkMode)
                    Button {
                    } label: {
                        Label("Backup", systemImage: "icloud.and.arrow.up")
                    }
                    Picker("Language", selection: $language) {
                        Text("English").tag("English")
                        Text("Chinese").tag("Chinese")
                        Text("French").tag("French")
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Free trial: 28 days")
                            .font(.system(.headline, design: .rounded))
                        Text("Pay once, use app forever.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text("CAD 1.99")
                            .font(.system(.title2, design: .rounded).weight(.semibold))
                    }
                    .padding(.vertical, 8)
                }
            }
            .scrollContentBackground(.hidden)
            .background(PaperBackground())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PaperBackground: View {
    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()
            Canvas { context, size in
                for index in 0..<90 {
                    let x = CGFloat((index * 47) % 397) / 397 * size.width
                    let y = CGFloat((index * 71) % 809) / 809 * size.height
                    let rect = CGRect(x: x, y: y, width: 1.1, height: 1.1)
                    context.fill(Path(ellipseIn: rect), with: .color(.ink.opacity(0.025)))
                }
            }
            .ignoresSafeArea()
        }
    }
}

extension Color {
    static let paper = Color(red: 0.985, green: 0.979, blue: 0.958)
    static let ink = Color(red: 0.07, green: 0.07, blue: 0.065)
    static let softGray = Color(red: 0.72, green: 0.73, blue: 0.72)
    static let mint = Color(red: 0.58, green: 0.82, blue: 0.68)
    static let blush = Color(red: 1.0, green: 0.66, blue: 0.66)
    static let butter = Color(red: 0.98, green: 0.86, blue: 0.35)
    static let peach = Color(red: 1.0, green: 0.61, blue: 0.55)
    static let sky = Color(red: 0.56, green: 0.72, blue: 0.94)
}
