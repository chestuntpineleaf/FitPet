import Foundation
import CoreLocation
import WeatherKit

@MainActor
class LocationWeatherManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var cityName: String = ""
    @Published var weather: WeatherSnapshot?
    @Published var locationFeature: LocationFeature = .urban
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func fetchLocationAndWeather() {
        locationManager.requestLocation()
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
            await self.reverseGeocode(location)
            await self.fetchWeather(location)
            self.detectLocationFeature(location)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
    
    private func reverseGeocode(_ location: CLLocation) async {
        let geocoder = CLGeocoder()
        if let placemark = try? await geocoder.reverseGeocodeLocation(location).first {
            cityName = [placemark.locality, placemark.administrativeArea]
                .compactMap { $0 }
                .joined(separator: ", ")
        }
    }
    
    private func fetchWeather(_ location: CLLocation) async {
        do {
            let weatherService = WeatherService.shared
            let current = try await weatherService.weather(for: location).currentWeather
            weather = WeatherSnapshot(
                temperature: current.temperature.value,
                feelsLike: current.apparentTemperature.value,
                condition: current.condition.description,
                humidity: current.humidity * 100,
                uvIndex: current.uvIndex.value,
                windSpeed: current.wind.speed.value,
                isDaylight: current.isDaylight
            )
        } catch {
            print("Weather fetch failed: \(error)")
        }
    }
    
    private func detectLocationFeature(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        Task {
            if let placemark = try? await geocoder.reverseGeocodeLocation(location).first {
                if let ocean = placemark.ocean, !ocean.isEmpty {
                    locationFeature = .coastal
                } else if let area = placemark.locality?.lowercased(),
                          area.contains("mountain") || area.contains("山") {
                    locationFeature = .mountain
                } else if placemark.inlandWater != nil {
                    locationFeature = .lakeside
                } else {
                    locationFeature = .urban
                }
            }
        }
    }
}

struct WeatherSnapshot {
    let temperature: Double
    let feelsLike: Double
    let condition: String
    let humidity: Double
    let uvIndex: Int
    let windSpeed: Double
    let isDaylight: Bool
    
    var isGoodForOutdoor: Bool {
        temperature > 5 && temperature < 35 && windSpeed < 40
    }
    
    var summary: String {
        let tempStr = String(format: "%.0f°C", temperature)
        return "\(condition) \(tempStr)"
    }
}

enum LocationFeature: String {
    case coastal
    case mountain
    case lakeside
    case urban
    
    var suggestedActivities: [String] {
        switch self {
        case .coastal: return ["游泳", "冲浪", "潜水", "沙滩排球", "海边跑步"]
        case .mountain: return ["徒步", "攀岩", "越野跑", "滑雪", "山地骑行"]
        case .lakeside: return ["划船", "钓鱼", "环湖跑", "游泳", "瑜伽"]
        case .urban: return ["健身房", "跑步", "骑行", "羽毛球", "游泳馆"]
        }
    }
    
    var displayName: String {
        switch self {
        case .coastal: return "海边"
        case .mountain: return "山区"
        case .lakeside: return "湖边"
        case .urban: return "城市"
        }
    }
}
