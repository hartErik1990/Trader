/// Copyright (c) 2020 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, ation, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation

struct Shared {
    struct UpdateDevice: Codable {
         let id: UUID?
         let pushToken: String?
         let system: Device.System
         let osVersion: String
         let channels: [String]?
        
         init(id: UUID? = nil, pushToken: String? = nil, system: Device.System, osVersion: String, channels: [String]? = nil) {
            self.id = id
            self.pushToken = pushToken
            self.system = system
            self.osVersion = osVersion
            self.channels = channels
        }
    }
    
     struct Device: Codable {
         enum System: String, Codable {
            case iOS
            case android
        }
        
         let id: UUID
         let system: System
         var osVersion: String
         var pushToken: String?
         var channels: [String]
        
         init(id: UUID, system: System, osVersion: String, pushToken: String?, channels: [String]) {
            self.id = id
            self.system = system
            self.osVersion = osVersion
            self.pushToken = pushToken
            self.channels = channels
        }
    }
    
    
     struct Airport: Codable {
         let id: UUID
         let iataCode: String
         let longName: String
        
         init(id: UUID, iataCode: String, longName: String) {
            self.id = id
            self.iataCode = iataCode
            self.longName = longName
        }
    }
    
    struct Flight: Codable {
         let id: UUID
         let arrivalAirport: Airport
         let flightNumber: String
        
         init(id: UUID, arrivalAirport: Airport, flightNumber: String) {
            self.id = id
            self.arrivalAirport = arrivalAirport
            self.flightNumber = flightNumber
        }
    }
}
