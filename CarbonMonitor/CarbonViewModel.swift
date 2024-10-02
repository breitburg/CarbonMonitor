//
//  CarbonViewModel.swift
//  CarbonMonitor
//
//  Created by Ilia Breitburg on 02/10/2024.
//

import Foundation

class CarbonViewModel: ObservableObject {
    @Published var powerUsage: Double = 0.0
        @Published var carbonIntensity: Double = 0.0
        @Published var co2Emission: Double = 0.0

        private let apiKey = ""

        func updateData() {
            estimatePowerUsage()
            fetchCarbonIntensity { intensity in
                DispatchQueue.main.async {
                    self.carbonIntensity = intensity
                    self.calculateCO2Emission()
                }
            }
        }

        private func estimatePowerUsage() {
            // Placeholder estimation of power usage in Watts
            // You can enhance this with more sophisticated calculations
            let cpuUsage = getCPUUsage()
            powerUsage = 10 + (cpuUsage * 20) // Base power + CPU usage estimation
        }

        private func calculateCO2Emission() {
            // CO2 Emission in grams per hour
            co2Emission = (powerUsage / 1000) * carbonIntensity
        }

        private func fetchCarbonIntensity(completion: @escaping (Double) -> Void) {
            // Fetch user's location from ipinfo.io
            let url = URL(string: "https://ipinfo.io/json")!

            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, error == nil else {
                    print("Failed to fetch location")
                    completion(0)
                    return
                }
                
                // Parse the location data to extract latitude and longitude
                do {
                    if let locationData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let loc = locationData["loc"] as? String {
                        let coordinates = loc.split(separator: ",")
                        if coordinates.count == 2,
                           let latitude = Double(coordinates[0]),
                           let longitude = Double(coordinates[1]) {
                            // Call the function to fetch the carbon intensity
                            self.getCarbonIntensity(latitude: latitude, longitude: longitude, completion: completion)
                        } else {
                            print("Failed to parse coordinates")
                            completion(0)
                        }
                    } else {
                        print("Failed to decode location data")
                        completion(0)
                    }
                } catch {
                    print("Error during JSON serialization: \(error.localizedDescription)")
                    completion(0)
                }
            }.resume()
        }


        private func getCarbonIntensity(latitude: Double, longitude: Double, completion: @escaping (Double) -> Void) {
            let urlString = "https://api.electricitymap.org/v3/carbon-intensity/nearest?lat=\(latitude)&lon=\(longitude)"
            var request = URLRequest(url: URL(string: urlString)!)
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print("Failed to fetch carbon intensity")
                    completion(0)
                    return
                }
                if let carbonData = try? JSONDecoder().decode(CarbonIntensity.self, from: data) {
                    completion(carbonData.data.carbonIntensity)
                } else {
                    print("Failed to decode carbon intensity data")
                    completion(0)
                }
            }.resume()
        }


        private func getCPUUsage() -> Double {
            var kr: kern_return_t
            var task_info_count: mach_msg_type_number_t

            task_info_count = mach_msg_type_number_t(TASK_INFO_MAX)
            let tinfo = UnsafeMutablePointer<integer_t>.allocate(capacity: Int(task_info_count))

            kr = task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), tinfo, &task_info_count)
            if kr != KERN_SUCCESS {
                return -1
            }

            var thread_list: thread_act_array_t?
            var thread_count: mach_msg_type_number_t = 0
            defer {
                if let thread_list = thread_list {
                    let thread_list_size = Int(thread_count)
                    vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: thread_list)), vm_size_t(thread_list_size))
                }
            }

            kr = task_threads(mach_task_self_, &thread_list, &thread_count)
            if kr != KERN_SUCCESS {
                return -1
            }

            var tot_cpu: Double = 0

            if let thread_list = thread_list {
                for i in 0..<Int(thread_count) {
                    var thread_info_count = mach_msg_type_number_t(THREAD_INFO_MAX)
                    let thinfo = thread_info_t.allocate(capacity: Int(thread_info_count))

                    kr = thread_info(thread_list[i], thread_flavor_t(THREAD_BASIC_INFO), thinfo, &thread_info_count)
                    if kr != KERN_SUCCESS {
                        return -1
                    }

                    let threadBasicInfo = convertThreadInfoToThreadBasicInfo(thinfo)

                    if threadBasicInfo.flags != TH_FLAGS_IDLE {
                        tot_cpu += Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
                    }
                    thinfo.deallocate()
                }
            }
            return tot_cpu / 100.0 // Return as a fraction between 0 and 1
        }

        private func convertThreadInfoToThreadBasicInfo(_ threadInfo: thread_info_t) -> thread_basic_info {
            return threadInfo.withMemoryRebound(to: thread_basic_info.self, capacity: 1) {
                $0.pointee
            }
        }
}

// Models
struct CarbonIntensity: Codable {
    let data: CarbonData
}

struct CarbonData: Codable {
    let carbonIntensity: Double
}

struct Location: Codable {
    let latitude: String
    let longitude: String
}

// Notification Extension
extension Notification.Name {
    static let updateData = Notification.Name("updateData")
}
