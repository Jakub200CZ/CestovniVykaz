//
//  LiveView.swift
//  CestovniVykaz
//
//  Live záznam – mapa, jízda/práce, časová osa, uložení do výkazů.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

// MARK: - Zaokrouhlení na započatou půlhodinu (nahoru)
func roundUpToHalfHour(_ hours: Double) -> Double {
    let minutes = hours * 60
    let roundedMinutes = ceil(minutes / 30) * 30
    return roundedMinutes / 60
}

// MARK: - Typ segmentu Live
enum LiveSegmentType: String, Codable {
    case drive = "jízda"
    case work = "práce"
}

// MARK: - Jeden segment (jízda nebo práce) v časové ose
struct LiveSegment: Identifiable, Codable {
    var id = UUID()
    let type: LiveSegmentType
    let startDate: Date
    var endDate: Date?
    var trackPoints: [TrackPoint]
    var kilometers: Double
    var placeName: String
    
    var durationHours: Double {
        let end = endDate ?? Date()
        return end.timeIntervalSince(startDate) / 3600
    }
    
    var durationRoundedHours: Double {
        roundUpToHalfHour(durationHours)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, type, startDate, endDate, trackPoints, kilometers, placeName
    }
    
    init(id: UUID = UUID(), type: LiveSegmentType, startDate: Date, endDate: Date?, trackPoints: [TrackPoint], kilometers: Double, placeName: String) {
        self.id = id
        self.type = type
        self.startDate = startDate
        self.endDate = endDate
        self.trackPoints = trackPoints
        self.kilometers = kilometers
        self.placeName = placeName
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        type = try c.decode(LiveSegmentType.self, forKey: .type)
        startDate = try c.decode(Date.self, forKey: .startDate)
        endDate = try c.decodeIfPresent(Date.self, forKey: .endDate)
        trackPoints = try c.decode([TrackPoint].self, forKey: .trackPoints)
        kilometers = try c.decode(Double.self, forKey: .kilometers)
        placeName = try c.decode(String.self, forKey: .placeName)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(type, forKey: .type)
        try c.encode(startDate, forKey: .startDate)
        try c.encodeIfPresent(endDate, forKey: .endDate)
        try c.encode(trackPoints, forKey: .trackPoints)
        try c.encode(kilometers, forKey: .kilometers)
        try c.encode(placeName, forKey: .placeName)
    }
}

// MARK: - Location Manager (podpora běhu na pozadí a při zamčeném telefonu)
final class LocationManager: NSObject, ObservableObject {
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    /// Volá se při každé nové poloze – používá se i na pozadí pro přidávání bodů trasy
    var onLocationUpdate: ((CLLocation) -> Void)?
    
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        authorizationStatus = manager.authorizationStatus
    }
    
    /// Žádat o povolení pouze pokud ještě nebylo uděleno ani odepřeno (není potřeba se ptát opakovaně).
    func requestPermissionIfNeeded() {
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            break
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }
    
    /// Spustit sledování polohy (běžné – pouze při použití aplikace)
    func startUpdatingLocation() {
        manager.allowsBackgroundLocationUpdates = false
        manager.pausesLocationUpdatesAutomatically = true
        manager.startUpdatingLocation()
    }
    
    /// Spustit sledování v režimu záznamu – stejná konfigurace jako běžná mapa (bez pozadí).
    func startUpdatingLocationForRecording() {
        manager.allowsBackgroundLocationUpdates = false
        manager.pausesLocationUpdatesAutomatically = true
        manager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        manager.allowsBackgroundLocationUpdates = false
        manager.stopUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async { [weak self] in
            self?.userLocation = location
            self?.onLocationUpdate?(location)
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .denied {
            errorMessage = "Pro Live záznam je potřeba povolit polohu v Nastavení."
        } else {
            errorMessage = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = error.localizedDescription
    }
}

// MARK: - Live View
struct LiveView: View {
    @ObservedObject var viewModel: MechanicViewModel
    @Binding var selectedTab: Int
    
    @StateObject private var locationManager = LocationManager()
    @State private var isRecording = false
    @State private var recordingType: LiveSegmentType = .drive
    @State private var segments: [LiveSegment] = []
    @State private var currentSegmentStart: Date?
    @State private var currentTrackPoints: [TrackPoint] = []
    @State private var lastLocation: CLLocation?
    @State private var showingSaveSuccess = false
    @State private var showingSettings = false
    @State private var showingSummary = false
    @State private var showingDeleteConfirm = false
    @State private var currentCityName: String?
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()
    
    private var mapPosition: MapCameraPosition {
        if let loc = locationManager.userLocation {
            return .region(MKCoordinateRegion(center: loc.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
        }
        return .automatic
    }
    
    /// Celkový čas jízdy v aktuálním běhu (dokončené segmenty + běžící), bez zaokrouhlení
    private var currentSessionDriveHours: Double {
        let fromSegments = segments.filter { $0.type == .drive }.reduce(0) { $0 + $1.durationHours }
        if isRecording, recordingType == .drive, let start = currentSegmentStart {
            return fromSegments + Date().timeIntervalSince(start) / 3600
        }
        return fromSegments
    }
    
    /// Celkový čas práce v aktuálním běhu, bez zaokrouhlení
    private var currentSessionWorkHours: Double {
        let fromSegments = segments.filter { $0.type == .work }.reduce(0) { $0 + $1.durationHours }
        if isRecording, recordingType == .work, let start = currentSegmentStart {
            return fromSegments + Date().timeIntervalSince(start) / 3600
        }
        return fromSegments
    }
    
    /// Celkové km v aktuálním běhu (jen z jízd)
    private var currentSessionKilometers: Double {
        let fromSegments = segments.filter { $0.type == .drive }.reduce(0) { $0 + $1.kilometers }
        if isRecording, recordingType == .drive, !currentTrackPoints.isEmpty {
            return fromSegments + calculateKilometers(currentTrackPoints)
        }
        return fromSegments
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let city = currentCityName {
                    HStack(spacing: 2) {
                        Text("📍")
                        Text(city)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 4)
                }
                
                // Mapa (neinteraktivní – bez posouvání a zoomu)
                Map(position: .constant(mapPosition)) {
                    if let loc = locationManager.userLocation {
                        Annotation("Vy", coordinate: loc.coordinate) {
                            Circle()
                                .fill(.blue)
                                .frame(width: 16, height: 16)
                                .overlay(Circle().stroke(.white, lineWidth: 3))
                        }
                    }
                    if isRecording && recordingType == .drive && !currentTrackPoints.isEmpty {
                        MapPolyline(coordinates: currentTrackPoints.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) })
                            .stroke(.blue, lineWidth: 4)
                    }
                }
                .mapStyle(.standard)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .allowsHitTesting(false)
                
                // Rychlý náhled: čas jízdy, čas práce, km (bez zaokrouhlení)
                HStack(spacing: 24) {
                    VStack(spacing: 2) {
                        Text("Jízda")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(formatDurationRaw(currentSessionDriveHours))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    VStack(spacing: 2) {
                        Text("Práce")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(formatDurationRaw(currentSessionWorkHours))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    VStack(spacing: 2) {
                        Text("Km")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f", currentSessionKilometers))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.top, 4)
                .padding(.horizontal)
                
                if let msg = locationManager.errorMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }
                
                // Tlačítka Začít / Ukončit záznam
                HStack(spacing: 16) {
                    Button(action: startRecording) {
                        Label("Začít záznam", systemImage: "record.circle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isRecording)
                    .opacity(isRecording ? 0.5 : 1)
                    
                    Button(action: endRecordingAndShowSummary) {
                        Label("Ukončit záznam", systemImage: "stop.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.red)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!isRecording)
                    .opacity(isRecording ? 1 : 0.5)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Přepínač Jízda / Práce (při záznamu ukončí aktuální segment a začne nový)
                HStack(spacing: 12) {
                    Button(action: {
                        if isRecording { switchToSegmentType(.drive) } else { recordingType = .drive }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "car.fill")
                            Text("Jízda")
                        }
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(recordingType == .drive ? Color.blue : Color(.systemGray5))
                        .foregroundStyle(recordingType == .drive ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    Button(action: {
                        if isRecording { switchToSegmentType(.work) } else { recordingType = .work }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "wrench.fill")
                            Text("Práce")
                        }
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(recordingType == .work ? Color.green : Color(.systemGray5))
                        .foregroundStyle(recordingType == .work ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
                
                if !segments.isEmpty && !isRecording {
                    HStack(spacing: 12) {
                        Button(action: saveToReports) {
                            Label("Uložit do výkazů", systemImage: "square.and.arrow.down")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        Button(action: { showingDeleteConfirm = true }) {
                            Image(systemName: "trash.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.top, 6)
                }
                
                // Časová osa úkonů
                VStack(alignment: .leading, spacing: 8) {
                    Text("Časová osa úkonů")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    if segments.isEmpty && !isRecording {
                        Text("Zatím žádné úkony. Začněte záznam a ukončete ho pro přidání do osy.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(segments) { seg in
                                    TimelineSegmentRow(segment: seg, dateFormatter: dateFormatter)
                                }
                                if isRecording, let start = currentSegmentStart {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(recordingType == .drive ? Color.blue : Color.green)
                                            .frame(width: 8, height: 8)
                                        Text("\(dateFormatter.string(from: start)) – nyní")
                                            .font(.caption)
                                        Text(recordingType == .drive ? "Jízda" : "Práce")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 200)
                    }
                }
                .padding(.top, 8)
                
                Spacer(minLength: 12)
            }
            .navigationTitle("Živý Záznam")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSummary) {
                LiveSummarySheet(
                    segments: segments,
                    onSaveToReports: {
                        saveToReports()
                        showingSummary = false
                    },
                    onDismiss: {
                        showingSummary = false
                    }
                )
            }
            .alert("Uloženo do výkazů", isPresented: $showingSaveSuccess) {
                Button("OK") {
                    selectedTab = 3
                }
            } message: {
                Text("Data byla uložena do historie výkazů. Můžete je upravit v Historie.")
            }
            .alert("Smazat celý záznam?", isPresented: $showingDeleteConfirm) {
                Button("Zrušit", role: .cancel) {}
                Button("Smazat", role: .destructive) {
                    segments = []
                    clearSegmentsCache()
                }
            } message: {
                Text("Všechny segmenty a data záznamu budou trvale vymazány. Tuto akci nelze vrátit zpět.")
            }
            .onAppear {
                locationManager.requestPermissionIfNeeded()
                restoreSessionIfNeeded()
                if !isRecording {
                    loadCachedSegmentsIfNeeded()
                    locationManager.startUpdatingLocation()
                }
                if let loc = locationManager.userLocation {
                    updateCityName(for: loc)
                }
            }
            .onDisappear {
                if !isRecording {
                    locationManager.stopUpdatingLocation()
                    locationManager.onLocationUpdate = nil
                }
            }
            .onChange(of: locationManager.userLocation) { _, newValue in
                if let loc = newValue {
                    addTrackPointIfNeeded(loc)
                    updateCityName(for: loc)
                }
            }
        }
    }
    
    private func startRecording() {
        clearSegmentsCache()
        currentSegmentStart = Date()
        currentTrackPoints = []
        lastLocation = locationManager.userLocation
        if recordingType == .drive, let loc = locationManager.userLocation {
            currentTrackPoints.append(TrackPoint(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude, timestamp: Date()))
        }
        isRecording = true
        locationManager.onLocationUpdate = { [self] loc in
            addTrackPointIfNeeded(loc)
        }
        locationManager.startUpdatingLocationForRecording()
        persistCurrentSession()
    }
    
    private func addTrackPointIfNeeded(_ location: CLLocation) {
        guard isRecording, recordingType == .drive else { return }
        let minDistance: CLLocationDistance = 15
        if let last = lastLocation, location.distance(from: last) < minDistance { return }
        currentTrackPoints.append(TrackPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, timestamp: Date()))
        lastLocation = location
        persistCurrentSession()
    }
    
    /// Ukončit aktuální segment a zobrazit souhrn (segmenty se uloží do mezipaměti)
    private func endRecordingAndShowSummary() {
        endCurrentSegment()
        isRecording = false
        locationManager.stopUpdatingLocation()
        locationManager.onLocationUpdate = nil
        clearPersistedSession()
        persistSegmentsToCache()
        showingSummary = true
    }
    
    /// Při záznamu přepnout typ: ukončit aktuální segment a začít nový (Jízda nebo Práce)
    private func switchToSegmentType(_ type: LiveSegmentType) {
        endCurrentSegment()
        recordingType = type
        currentSegmentStart = Date()
        currentTrackPoints = []
        lastLocation = locationManager.userLocation
        if type == .drive, let loc = locationManager.userLocation {
            currentTrackPoints.append(TrackPoint(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude, timestamp: Date()))
        }
        persistCurrentSession()
    }
    
    /// Ukončit aktuální segment a přidat ho do seznamu (bez zastavení záznamu)
    private func endCurrentSegment() {
        guard isRecording, let start = currentSegmentStart else { return }
        
        let end = Date()
        var km: Double = 0
        if recordingType == .drive, let loc = locationManager.userLocation {
            currentTrackPoints.append(TrackPoint(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude, timestamp: end))
            km = calculateKilometers(currentTrackPoints)
        }
        
        let placeName = "Místo práce"
        let segment = LiveSegment(
            type: recordingType,
            startDate: start,
            endDate: end,
            trackPoints: recordingType == .drive ? currentTrackPoints : [],
            kilometers: km,
            placeName: placeName
        )
        segments.append(segment)
        
        if recordingType == .work, let loc = locationManager.userLocation {
            let segmentIndex = segments.count - 1
            Task {
                if let name = await resolvePlaceName(loc) {
                    await MainActor.run {
                        if segmentIndex < segments.count {
                            segments[segmentIndex].placeName = name
                        }
                    }
                }
            }
        }
        
        currentSegmentStart = nil
        currentTrackPoints = []
        lastLocation = nil
    }
    
    private func stopRecording() {
        endCurrentSegment()
        isRecording = false
        locationManager.stopUpdatingLocation()
        locationManager.onLocationUpdate = nil
        clearPersistedSession()
    }
    
    private func formatDurationRaw(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        let h = totalMinutes / 60
        let min = totalMinutes % 60
        return "\(h):\(String(format: "%02d", min))"
    }
    
    private func updateCityName(for location: CLLocation) {
        Task {
            if let name = await resolvePlaceName(location) {
                await MainActor.run {
                    currentCityName = name
                }
            }
        }
    }
    
    private func saveToReports() {
        guard !segments.isEmpty else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let driveSegments = segments.filter { $0.type == .drive }
        let workSegments = segments.filter { $0.type == .work }
        
        let totalDrivingRounded = driveSegments.reduce(0) { $0 + roundUpToHalfHour($1.durationHours) }
        let totalWorkingRounded = workSegments.reduce(0) { $0 + roundUpToHalfHour($1.durationHours) }
        let totalKm = driveSegments.reduce(0) { $0 + $1.kilometers }
        let allTrackPoints = driveSegments.flatMap { $0.trackPoints }
        let city = workSegments.first?.placeName ?? driveSegments.first?.placeName ?? ""
        
        let workDay = WorkDay(
            date: today,
            customerName: "Live záznam",
            drivingHours: totalDrivingRounded,
            workingHours: totalWorkingRounded,
            kilometers: totalKm,
            city: city,
            notes: "Automaticky z Live záznamu",
            isCompleted: false,
            dayType: .work,
            trackPoints: allTrackPoints.isEmpty ? nil : allTrackPoints
        )
        
        viewModel.addWorkDay(workDay)
        segments = []
        clearPersistedSession()
        clearSegmentsCache()
        showingSaveSuccess = true
    }
    
    private func calculateKilometers(_ points: [TrackPoint]) -> Double {
        guard points.count >= 2 else { return 0 }
        var total: Double = 0
        for i in 1..<points.count {
            let a = points[i - 1]
            let b = points[i]
            let from = CLLocation(latitude: a.latitude, longitude: a.longitude)
            let to = CLLocation(latitude: b.latitude, longitude: b.longitude)
            total += from.distance(from: to) / 1000
        }
        return total
    }
    
    // MARK: - Persistence (obnova záznamu po ukončení aplikace)
    private static let liveSessionRecordingKey = "liveSessionRecording"
    private static let liveSessionStartKey = "liveSessionStart"
    private static let liveSessionTypeKey = "liveSessionType"
    private static let liveSessionTrackPointsKey = "liveSessionTrackPoints"
    
    // MARK: - Mezipaměť ukončeného záznamu (přežije vypnutí / kill aplikace)
    private static let liveCachedSegmentsKey = "liveCachedSegments"
    
    private func persistSegmentsToCache() {
        guard !segments.isEmpty else { return }
        if let data = try? JSONEncoder().encode(segments) {
            UserDefaults.standard.set(data, forKey: Self.liveCachedSegmentsKey)
        }
    }
    
    private func loadCachedSegmentsIfNeeded() {
        guard segments.isEmpty else { return }
        guard let data = UserDefaults.standard.data(forKey: Self.liveCachedSegmentsKey),
              let decoded = try? JSONDecoder().decode([LiveSegment].self, from: data) else { return }
        segments = decoded
    }
    
    private func clearSegmentsCache() {
        UserDefaults.standard.removeObject(forKey: Self.liveCachedSegmentsKey)
    }
    
    private func persistCurrentSession() {
        guard isRecording, let start = currentSegmentStart else { return }
        UserDefaults.standard.set(true, forKey: Self.liveSessionRecordingKey)
        UserDefaults.standard.set(start.timeIntervalSince1970, forKey: Self.liveSessionStartKey)
        UserDefaults.standard.set(recordingType.rawValue, forKey: Self.liveSessionTypeKey)
        if let data = try? JSONEncoder().encode(currentTrackPoints) {
            UserDefaults.standard.set(data, forKey: Self.liveSessionTrackPointsKey)
        }
    }
    
    private func clearPersistedSession() {
        UserDefaults.standard.removeObject(forKey: Self.liveSessionRecordingKey)
        UserDefaults.standard.removeObject(forKey: Self.liveSessionStartKey)
        UserDefaults.standard.removeObject(forKey: Self.liveSessionTypeKey)
        UserDefaults.standard.removeObject(forKey: Self.liveSessionTrackPointsKey)
    }
    
    private func restoreSessionIfNeeded() {
        guard UserDefaults.standard.bool(forKey: Self.liveSessionRecordingKey) else { return }
        let startInterval = UserDefaults.standard.double(forKey: Self.liveSessionStartKey)
        guard startInterval > 0 else { clearPersistedSession(); return }
        let start = Date(timeIntervalSince1970: startInterval)
        let calendar = Calendar.current
        guard calendar.isDateInToday(start) else { clearPersistedSession(); return }
        let typeRaw = UserDefaults.standard.string(forKey: Self.liveSessionTypeKey) ?? LiveSegmentType.drive.rawValue
        let type = LiveSegmentType(rawValue: typeRaw) ?? .drive
        var points: [TrackPoint] = []
        if let data = UserDefaults.standard.data(forKey: Self.liveSessionTrackPointsKey),
           let decoded = try? JSONDecoder().decode([TrackPoint].self, from: data) {
            points = decoded
        }
        currentSegmentStart = start
        currentTrackPoints = points
        recordingType = type
        isRecording = true
        lastLocation = locationManager.userLocation
        locationManager.onLocationUpdate = { [self] loc in addTrackPointIfNeeded(loc) }
        locationManager.startUpdatingLocationForRecording()
    }
    
}

private func resolvePlaceName(_ location: CLLocation) async -> String? {
    await withCheckedContinuation { continuation in
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            let name = placemarks?.first?.locality ?? placemarks?.first?.administrativeArea
            continuation.resume(returning: name)
        }
    }
}

// MARK: - Souhrn po ukončení záznamu
struct LiveSummarySheet: View {
    let segments: [LiveSegment]
    let onSaveToReports: () -> Void
    let onDismiss: () -> Void
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()
    
    private var totalDriveHours: Double {
        segments.filter { $0.type == .drive }.reduce(0) { $0 + $1.durationHours }
    }
    
    private var totalWorkHours: Double {
        segments.filter { $0.type == .work }.reduce(0) { $0 + $1.durationHours }
    }
    
    private var totalKm: Double {
        segments.filter { $0.type == .drive }.reduce(0) { $0 + $1.kilometers }
    }
    
    private func formatDuration(_ hours: Double) -> String {
        let m = Int(hours * 60)
        let h = m / 60
        let min = m % 60
        return "\(h):\(String(format: "%02d", min))"
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Souhrn") {
                    HStack {
                        Text("Čas jízdy")
                        Spacer()
                        Text(formatDuration(totalDriveHours))
                            .fontWeight(.medium)
                    }
                    HStack {
                        Text("Čas práce")
                        Spacer()
                        Text(formatDuration(totalWorkHours))
                            .fontWeight(.medium)
                    }
                    HStack {
                        Text("Kilometry")
                        Spacer()
                        Text(String(format: "%.0f km", totalKm))
                            .fontWeight(.medium)
                    }
                }
                
                Section("Úkony") {
                    ForEach(segments) { seg in
                        TimelineSegmentRow(segment: seg, dateFormatter: dateFormatter)
                    }
                }
                
                Section {
                    Button(action: onSaveToReports) {
                        Label("Uložit do výkazů", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Zavřít", role: .cancel, action: onDismiss)
                }
            }
            .navigationTitle("Souhrn")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Řádek segmentu v časové ose
struct TimelineSegmentRow: View {
    let segment: LiveSegment
    let dateFormatter: DateFormatter
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(segment.type == .drive ? Color.blue : Color.green)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 2) {
                if let end = segment.endDate {
                    Text("\(dateFormatter.string(from: segment.startDate)) – \(dateFormatter.string(from: end))")
                        .font(.caption)
                        .fontWeight(.medium)
                } else {
                    Text(dateFormatter.string(from: segment.startDate))
                        .font(.caption)
                }
                Text(segment.type == .drive ? "Jízda" : "Práce")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if segment.type == .drive && segment.kilometers > 0 {
                    Text(String(format: "%.0f km", segment.kilometers))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if segment.type == .work && !segment.placeName.isEmpty {
                    Text(segment.placeName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text("\(formatRoundedHours(segment.durationRoundedHours)) h")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func formatRoundedHours(_ hours: Double) -> String {
        let m = Int(hours * 60)
        let h = m / 60
        let min = m % 60
        if min == 0 {
            return "\(h)"
        }
        return "\(h):\(String(format: "%02d", min))"
    }
}
