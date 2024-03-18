//
//  ViewController.swift
//  Lab-03_WeatherApp
//
//  Created by Mohaymin Islam on 2024-03-15.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UISearchBarDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var weatherImageView: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var temperatureUnitSwitch: UISwitch!
    @IBOutlet weak var feelsLikeLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var weatherData: WeatherData?
    var currentTemperatureUnit: TemperatureUnit = .celsius // Default to Celsius
    
    enum TemperatureUnit {
        case celsius
        case fahrenheit
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        weatherImageView.image = UIImage(systemName: "cloud.sun.fill")
        
        // Fetch weather for current location on launch
        if let currentLocation = currentLocation {
            getWeatherByLocation(location: currentLocation)
        } else {
            locationLabel.text = "Fetching location..."
        }
        
        // Initialize the UI with the current temperature unit
        updateTemperature()
    }
    
    // MARK: - Search Bar Delegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchTerm = searchBar.text else { return }
        getWeatherByCity(city: searchTerm)
        searchBar.resignFirstResponder()
    }
    
    // MARK: - Location Button Action
    
    @IBAction func locationButtonTapped(_ sender: UIButton) {
        if let currentLocation = currentLocation {
            getWeatherByLocation(location: currentLocation)
        }
    }
    
    // MARK: - Location Manager Delegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = location
            getWeatherByLocation(location: location) // Update weather when location changes
        }
    }
    
    // MARK: - Weather API Functions
    
    func getWeatherByCity(city: String) {
        // Make API call to get weather by city
        let apiKey = "93b59ed8457b4e6585b201936241403"
        let urlString = "https://api.weatherapi.com/v1/current.json?key=\(apiKey)&q=\(city)"
        
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
                        DispatchQueue.main.async {
                            self.weatherData = weatherData
                            self.updateUI(with: weatherData)
                        }
                    } catch {
                        print("Error decoding JSON: \(error)")
                    }
                }
            }.resume()
        }
    }
    
    func getWeatherByLocation(location: CLLocation) {
        // Make API call to get weather by location coordinates
        let apiKey = "93b59ed8457b4e6585b201936241403"
        let urlString = "https://api.weatherapi.com/v1/current.json?key=\(apiKey)&q=\(location.coordinate.latitude),\(location.coordinate.longitude)"
        
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
                        DispatchQueue.main.async {
                            self.weatherData = weatherData
                            self.updateUI(with: weatherData)
                        }
                    } catch {
                        print("Error decoding JSON: \(error)")
                    }
                }
            }.resume()
        }
    }
    
    // MARK: - UI Update Functions
    
    func updateUI(with weatherData: WeatherData) {
        // Print the condition string to debug
        if let condition = weatherData.current.condition {
            print("Condition: \(condition.text)")
            // Now, call getSymbolName function to see what symbol name it returns
            let symbolName = getSymbolName(for: condition.text.trimmingCharacters(in: .whitespacesAndNewlines))
            print("Symbol Name: \(symbolName)")
            // Update the image view with the retrieved symbol name
            if let image = UIImage(systemName: symbolName) {
                weatherImageView.image = image
            } else {
                print("SF Symbol named \(symbolName) not found")
            }
        }
        
        // Update temperature label
        updateTemperature()
        
        // Update location label
        locationLabel.text = weatherData.location.name
        
        // Update feels like label
        if let feelsLikeC = weatherData.current.feelslike_c {
            let feelsLike = currentTemperatureUnit == .celsius ? "\(feelsLikeC)°C" : "\(celsiusToFahrenheit(feelsLikeC))°F"
            feelsLikeLabel.text = "Feels like: \(feelsLike)"
        }
        
        // Update humidity label
        if let humidity = weatherData.current.humidity {
            humidityLabel.text = "Humidity: \(humidity)%"
        }
    }
    
    // MARK: - Temperature Unit Switch Action
    
    @IBAction func temperatureUnitSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            currentTemperatureUnit = .celsius
        } else {
            currentTemperatureUnit = .fahrenheit
        }
        updateTemperature()
    }
    
    // Update temperature display based on the switch state
    func updateTemperature() {
        if let tempC = weatherData?.current.temp_c {
            let temp = currentTemperatureUnit == .celsius ? "\(tempC)°C" : "\(celsiusToFahrenheit(tempC))°F"
            temperatureLabel.text = temp
            
            // Update feels like label
            if let feelsLikeC = weatherData?.current.feelslike_c {
                let feelsLike = currentTemperatureUnit == .celsius ? "\(feelsLikeC)°C" : "\(celsiusToFahrenheit(feelsLikeC))°F"
                feelsLikeLabel.text = "Feels like: \(feelsLike)"
            }
        }
    }
    
    
    // MARK: - Helper Functions
    func celsiusToFahrenheit(_ celsius: Double) -> Int {
        let fahrenheit = (celsius * 9/5) + 32
        return Int(round(fahrenheit))
    }
    
    //    func celsiusToFahrenheit(_ celsius: Double) -> Double {
    //        return (celsius * 9/5) + 32
    //    }
    
    // Helper function to map weather condition to SF Symbol name
    func getSymbolName(for weatherCondition: String) -> String {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        // Determine if it's night or day based on the hour
        let isNight = hour < 6 || hour > 18 // Assume night if hour is before 6 AM or after 6 PM
        
        switch weatherCondition.lowercased() {
        case "sunny":
            return "sun.max.fill"
        case "clear":
            return "sun.max.fill"
        case "partly cloudy":
            return "cloud.sun.fill"
        case "cloudy":
            return "cloud.fill"
        case "overcast":
            return "cloud.fill"
        case "mist":
            return "cloud.fog.fill"
        case "fog":
            return "cloud.fog.fill"
        case "freezing fog":
            return "cloud.fog.fill"
        case "patchy rain possible":
            return "cloud.rain.fill"
        case "patchy snow possible":
            return "cloud.snow.fill"
        case "patchy sleet possible":
            return "cloud.sleet.fill"
        case "patchy freezing drizzle possible":
            return "cloud.hail.fill"
        case "thundery outbreaks possible":
            return "cloud.bolt.fill"
        case "blowing snow":
            return "wind.snow"
        case "blizzard":
            return "wind.snow"
        case "patchy light drizzle":
            return "cloud.drizzle.fill"
        case "light rain":
            return "cloud.rain.fill"
        case "moderate rain at times":
            return "cloud.heavyrain.fill"
        case "heavy rain":
            return "cloud.heavyrain.fill"
        case "light freezing rain":
            return "cloud.sleet.fill"
        case "moderate or heavy freezing rain":
            return "cloud.sleet.fill"
        case "light sleet":
            return "cloud.sleet.fill"
        case "moderate or heavy sleet":
            return "cloud.sleet.fill"
        case "patchy light rain with thunder":
            return "cloud.bolt.rain.fill"
        case "moderate or heavy rain with thunder":
            return "cloud.bolt.rain.fill"
        case "patchy light snow with thunder":
            return "cloud.bolt.snow.fill"
        case "moderate or heavy snow with thunder":
            return "cloud.bolt.snow.fill"
        case "ice pellets":
            return "cloud.hail.fill"
        case "light rain shower":
            return "cloud.drizzle.fill"
        case "moderate or heavy rain shower":
            return "cloud.rain.fill"
        case "torrential rain shower":
            return "cloud.heavyrain.fill"
        case "light sleet showers":
            return "cloud.sleet.fill"
        case "moderate or heavy sleet showers":
            return "cloud.sleet.fill"
        case "light snow showers":
            return "cloud.snow.fill"
        case "moderate or heavy snow showers":
            return "cloud.snow.fill"
        case "patchy light rain in area with thunder":
            return "cloud.bolt.rain.fill"
        case "moderate or heavy rain in area with thunder":
            return "cloud.bolt.rain.fill"
        case "patchy snow in area with thunder":
            return "cloud.bolt.snow.fill"
        case "moderate or heavy snow in area with thunder":
            return "cloud.bolt.snow.fill"
        default:
            return isNight ? "moon.stars.fill" : "cloud.fill"
        }
    }
    
}

struct WeatherData: Codable {
    let location: Location
    let current: Current
}

struct Location: Codable {
    let name: String
}

struct Current: Codable {
    let temp_c: Double?
    let feelslike_c: Double?
    let humidity: Double?
    let condition: Condition?
}

struct Condition: Codable {
    let text: String
    
    enum CodingKeys: String, CodingKey {
        case text
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
    }
}
