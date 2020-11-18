//
//  File.swift
//
//
//  Created by Noah Kamara on 23.10.20.
//

import Foundation
import AVFoundation
import os


/// API Wrapper for Jellyfin API (Equivalent to Emby API)
public class API {
    
    /// API Models
    public class Models {}
    
    
    /// API Responses
    public class Responses {}
    
    
    /// API Errors
    public class Errors {}
    
    
    /// URL Scheme
    private let scheme: String
    
    /// Server host
    public let host: String
    
    /// Server port
    public let port: Int

    /// Client Device ID
    private let deviceId: String
    
    /// Authenticated User
    private var currentUser: AuthUser?
    
    /// Logger
    private var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "API")

    public init(_ host: String = "", _ port: Int = 8096, _ user: AuthUser? = nil, _ deviceID: String? = nil, _ isHttpsEnabled: Bool = false) {
        self.host = host
        self.port = port
        self.deviceId = user?.deviceID ?? deviceID ?? UUID().uuidString
        self.currentUser = user
        self.scheme = isHttpsEnabled ? "https" : "http"
    }
    
    
    /// true if the API Wrapper has a valid adress
    public var hasAddress: Bool {
        return self.host != "" && self.host != "localhost"
    }

    
    /// Creates URLRequest with given parameters
    /// - Parameters:
    ///   - path: URL Path
    ///   - params: Query Items
    ///   - headers: Headers
    /// - Returns: URLRequest
    private func makeRequest(_ path: String, _ params: [String: String?] = [:], _ headers: [String: String] = [:]) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = self.scheme
        urlComponents.host = self.host
        urlComponents.port = self.port
        urlComponents.path = path
        if !params.isEmpty {
            urlComponents.queryItems = params.map({URLQueryItem(name: $0.key, value: $0.value)})
        }
        let url = urlComponents.url!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = [
            "Content-type": "application/json",
            "X-Emby-Authorization": "Emby Client=abjc, Device=iOS, DeviceId=\(self.deviceId), Version=1.0.0",
            "X-Emby-Token": self.currentUser?.token ?? ""
        ]
        request.timeoutInterval = 60.0
        return request
    }

    
    /// Executes HTTP Request (GET)
    /// - Parameters:
    ///   - path: URL Path
    ///   - params: Query Items
    ///   - completion: API Response Completion
    private func get(_ path: String, _ params: [String: String?] = [:], completion: @escaping Completions.Response) {
        let request = self.makeRequest(path, params)
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                self.logger.notice("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") ERROR")
                self.logger.debug("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") \(error.localizedDescription)")
                completion(.failure(error))
            }

            if let httpResponse = response as? HTTPURLResponse {
                do {
                    try Errors.ServerError.make(httpResponse.statusCode)
                } catch let error {
                    self.logger.notice("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") ERROR")
                    self.logger.debug("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }

            if let data = data {
                self.logger.debug("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") SUCCESS")
                completion(.success(data))
            }
        }.resume()
    }

    /// Executes HTTP Request (POST)
    /// - Parameters:
    ///   - path: URL Path
    ///   - data: Post Data
    ///   - completion: API Response Completion
    private func post(_ path: String, _ data: Data? = nil, _ completion: @escaping Completions.Basic) {
        var urlComponents = URLComponents()
        urlComponents.scheme = self.scheme
        urlComponents.host = self.host
        urlComponents.port = self.port
        urlComponents.path = path
        var request = self.makeRequest(path)
        request.httpMethod = "POST"
        request.httpBody = data

        URLSession.shared.dataTask(with: request) { [self] (data, response, error) in
            if let error = error {
                self.logger.notice("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") ERROR")
                self.logger.debug("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                if let httpResponse = response as? HTTPURLResponse {
                    do {
                        try Errors.ServerError.make(httpResponse.statusCode)
                    } catch let error {
                        self.logger.notice("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") ERROR")
                        self.logger.debug("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
                self.logger.debug("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") SUCCESS")
                completion(.success(nil))
            }
        }.resume()
    }

    /// Executes HTTP Request (DELETE)
    /// - Parameters:
    ///   - path: URL Path
    ///   - params: Query Items
    ///   - completion: API Basic Completion
    private func delete(_ path: String, _ params: [String: String?], _ data: Data, _ completion: @escaping Completions.Basic) {
        var request = self.makeRequest(path, params)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                self.logger.notice("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") ERROR")
                self.logger.debug("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                if let httpResponse = response as? HTTPURLResponse {
                    do {
                        try Errors.ServerError.make(httpResponse.statusCode)
                    } catch let error {
                        self.logger.notice("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") ERROR")
                        self.logger.debug("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
                self.logger.debug("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") SUCCESS")
                completion(.success(nil))
            }
        }.resume()
    }


    //MARK: Authorization
    
    
    /// Authenticates the given account
    /// - Parameters:
    ///   - username: Account Username
    ///   - password: Account Password
    ///   - completion: AuthResponse Completion
    private func authorizeByName(_ username: String, _ password: String, completion: @escaping Completions.AuthResponse) {
        var urlComponents = URLComponents()
        urlComponents.scheme = self.scheme
        urlComponents.host = self.host
        urlComponents.port = self.port
        urlComponents.path = "/Users/AuthenticateByName"
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.timeoutInterval = 5.0
        request.allHTTPHeaderFields = [
            "Content-type": "application/json",
            "X-Emby-Authorization": "Emby Client=abjc, Device=iOS, DeviceId=\(self.deviceId), Version=1.0.0",
        ]
        let jsonBody = [
            "Username": username,
            "Pw": password
        ]
        if let data = try? JSONEncoder().encode(jsonBody) {
            request.httpBody = data
            
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let httpResponse = response as? HTTPURLResponse {
                    do {
                        try Errors.ServerError.make(httpResponse.statusCode)
                    } catch let error {
                        self.logger.notice("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") ERROR")
                        self.logger.debug("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }
                }
                
                if let error = error {
                    self.logger.notice("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") ERROR")
                    self.logger.debug("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                if let data = data {
                    do {
                        let response = try JSONDecoder().decode(Responses.AuthResponse.self, from: data)
                        self.currentUser = AuthUser(id: response.user.id,
                                                    name: response.user.name,
                                                    serverID: response.serverId,
                                                    deviceID: self.deviceId,
                                                    token: response.token)
                        self.logger.debug("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") SUCCESS")
                        completion(.success(response))
                    } catch let error {
                        self.logger.notice("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") ERROR")
                        self.logger.debug("\(request.httpMethod?.uppercased() ?? "UNKNOWN") \(request.url?.absoluteString ?? "URL") \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
            }.resume()
        } else {
            print(jsonBody)
        }
    }

    
    // Authenticates the given account
    /// - Parameters:
    ///   - username: Account Username
    ///   - password: Account Password
    ///   - completion: AuthResponse Completion
    public func authorize(_ username: String, _ password: String, completion: @escaping Completions.AuthResponse) {
        self.logger.info("API.authorize started")
        self.logger.debug("API.authorize '\(username)' @ '\(self.host):\(self.port)'  ")
        self.authorizeByName(username, password) { result in
            self.logger.info("API.authorize completed")
            completion(result)
        }
    }


    //MARK: System Info
    
    
    /// Fetches the System Info from the Server
    /// - Parameter completion: SystemInfo Completion
    public func getSystemInfo(completion: @escaping Completions.SystemInfo) {
        self.logger.info("API.getSystemInfo started")
        let path = "/System/Info"
        self.get(path) { (result) in
            switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(API.Models.SystemInfo.self, from: data)
                        self.logger.info("API.getSystemInfo completed")
                        completion(.success(response))
                    } catch let error {
                        self.logger.notice("API.getSystemInfo ERROR")
                        self.logger.debug("API.getSystemInfo \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                case .failure(let error): completion(.failure(error))
            }
        }
    }




    //MARK: Query Items
    
    
    /// Retrieves all Items of the given type (or simply all items of type "Series" and "Movie" if no type is given)
    /// - Parameters:
    ///   - type: MediaType
    ///   - completion: Items Completion
    public func getItems(_ type: Models.MediaType? = nil, completion: @escaping Completions.Items) {
        self.logger.info("API.getItems started")
        self.logger.debug("API.getItems type: \(type?.rawValue ?? "none")")
        let path = "/emby/Users/\(self.currentUser?.id ?? "")/Items"
        let params = [
            "Recursive": String(true),
            "IncludeItemTypes": type?.rawValue ?? "Series,Movie",
            "Fields": "Genres,Overview"
        ]
        self.get(path, params) { (result) in
            switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(Responses.ItemResponse<[Models.Item]>.self, from: data)
                        self.logger.info("API.getItems completed")
                        completion(.success(response.items))
                    } catch let error {
                        self.logger.notice("API.getItems ERROR")
                        self.logger.debug("API.getItems \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                case .failure(let error): completion(.failure(error))
            }
        }
    }

    
    /// Retrieves Latest Items of given type (or "Series,Movie" if none given)
    /// - Parameters:
    ///   - type: MediaType
    ///   - completion: Items Completion
    public func getLatest(_ type: Models.MediaType? = nil, completion: @escaping Completions.Items) {
        self.logger.info("API.getLatest started")
        self.logger.debug("API.getLatest type: \(type?.rawValue ?? "none")")

        let path = "/emby/Users/\(self.currentUser?.id ?? "")/Items/Latest"
        let params = [
            "Recursive": String(true),
            "IncludeItemTypes": type?.rawValue ?? "Series,Movie",
            "Fields": "Genres",
            "Limit": String(12)
        ]
        self.get(path, params) { (result) in
            switch result {
                case .success(let data):
                    do {
                        let items = try JSONDecoder().decode([Models.Item].self, from: data)
                        self.logger.info("API.getLatest completed")
                        completion(.success(items))
                    } catch let error {
                        self.logger.notice("API.getLatest ERROR")
                        self.logger.debug("API.getLatest \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                case .failure(let error): completion(.failure(error))
            }
        }
    }

    /// Retrieves Resumable Items of given type (or "Series,Movie" if none given)
    /// - Parameters:
    ///   - type: MediaType
    ///   - completion: Items Completion
    public func getResumable(_ type: Models.MediaType? = nil, completion: @escaping Completions.Items) {
        self.logger.info("API.getResumable started")
        self.logger.debug("API.getResumable type: \(type?.rawValue ?? "none")")
        let path = "/emby/Users/\(self.currentUser?.id ?? "")/Items/Resume"
        let params = [
            "Recursive": String(true),
            "IncludeItemTypes": type?.rawValue ?? "Series,Movie",
            "SortBy": "DatePlayed",
            "SortOrder": "Descending",
            "Fields": "Genres"
        ]
        self.get(path, params) { (result) in
            switch result {
                case .success(let data):
                    do {
                        let res = try JSONDecoder().decode(Responses.ItemResponse<[Models.Item]>.self, from: data)
                        self.logger.info("API.getResumable completed")
                        completion(.success(res.items))
                    } catch let error {
                        print(error)
                        self.logger.notice("API.getResumable ERROR")
                        self.logger.debug("API.getResumable \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    /// Retrieves Next Up Episodes
    /// - Parameters:
    ///   - completion: Items Completion
    public func getNextUp(_ completion: @escaping Completions.Items) {
        self.logger.info("API.getNextUp started")
        let path = "/Shows/NextUp"
        let params = [
            "userId": currentUser?.id ?? ""
        ]
        self.get(path, params) { (result) in
            switch result {
                case .success(let data):
                    do {
                        let items = try JSONDecoder().decode([Models.Item].self, from: data)
                        self.logger.info("API.getNextUp completed")
                        completion(.success(items))
                    } catch let error {
                        self.logger.notice("API.getNextUp ERROR")
                        self.logger.debug("API.getNextUp \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                case .failure(let error): completion(.failure(error))
            }
        }
    }

    /// Retrieves Favorite Items of given type (or "Series,Movie" if none given)
    /// - Parameters:
    ///   - type: MediaType
    ///   - completion: Items Completion
    public func getFavorites(_ type: Models.MediaType? = nil, completion: @escaping Completions.Items) {
        self.logger.info("API.getFavorites started")
        self.logger.debug("API.getFavorites type: \(type?.rawValue ?? "none")")
        let path = "/emby/Users/\(self.currentUser?.id ?? "")/Items/Latest"
        let params = [
            "Recursive": String(true),
            "IncludeItemTypes": type?.rawValue ?? "Series,Movie",
            "Filters": "IsFavorite",
            "Fields": "Genres"
        ]
        self.get(path, params) { (result) in
            switch result {
                case .success(let data):
                    do {
                        let items = try JSONDecoder().decode([Models.Item].self, from: data)
                        self.logger.info("API.getResumable completed")
                        completion(.success(items))
                    } catch let error {
                        self.logger.notice("API.getResumable ERROR")
                        self.logger.debug("API.getResumable \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                case .failure(let error): completion(.failure(error))
            }
        }
    }

    /// Retrieves Similar Items to given Item (id)
    /// - Parameters:
    ///   - item_id: Item ID
    ///   - completion: Items Completion
    public func getSimilar(for item_id: String, completion: @escaping Completions.Items) {
        self.logger.info("API.getSimilar started")
        self.logger.debug("API.getSimilar item: \(item_id)")

        let path = "/Items/\(item_id)/Similar"
        let params = [
            "Recursive": String(true),
            "IncludeItemTypes": "Series,Movie",
            "Fields": "Genres",
            "userId": self.currentUser?.id ?? ""
        ]
        self.get(path, params) { (result) in
            switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(Responses.ItemResponse<[Models.Item]>.self, from: data)
                        self.logger.info("API.getSimilar completed")
                        completion(.success(response.items))
                    } catch let error {
                        self.logger.notice("API.getSimilar ERROR")
                        self.logger.debug("API.getSimilar \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                case .failure(let error): completion(.failure(error))
            }
        }
    }

    
    //MARK: Detail Items
    
    /// Retrieves all data for given Item ID
    /// - Parameters:
    ///   - item_id: Movie Item ID
    ///   - completion: Movie Completion
    public func getMovie(_ item_id: String, completion: @escaping Completions.Movie) {
        self.logger.info("API.getMovie started")
        self.logger.debug("API.getMovie item: \(item_id)")
        let path = "/Users/\(currentUser?.id ?? "")/Items/\(item_id)"

        self.get(path) { (result) in
            switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(Models.Movie.self, from: data)
                        self.logger.info("API.getMovie completed")
                        completion(.success(response))
                    } catch let error {
                        self.logger.notice("API.getMovie ERROR")
                        self.logger.debug("API.getMovie \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    /// Retrieves all data for given Item ID
    /// - Parameters:
    ///   - item_id: Series Item ID
    ///   - completion: Series Completion
    public func getSeries(_ item_id: String, completion: @escaping Completions.Series) {
        self.logger.info("API.getSeries started")
        self.logger.debug("API.getSeries item: \(item_id)")
        let path = "/Users/\(currentUser?.id ?? "")/Items/\(item_id)"
        let params = [
            "Fields": "Genres,Overview,People,MediaSources"
        ]
        self.get(path, params) { (result) in
            switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(Models.Series.self, from: data)
                        self.logger.info("API.getSeries completed")
                        completion(.success(response))
                    } catch let error {
                        self.logger.notice("API.getSeries ERROR")
                        self.logger.debug("API.getSeries \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    /// Retrieves all Seasons for given Series
    /// - Parameters:
    ///   - series_id: Series Item ID
    ///   - completion: Seasons Completion
    public func getSeasons(for series_id: String, completion: @escaping Completions.Seasons) {
        self.logger.info("API.getSeasons started")
        self.logger.debug("API.getSeasons series: \(series_id)")
        let path = "/Shows/\(series_id)/Seasons"
        let params = [
            "userId": self.currentUser?.id ?? "",
            "IncludeItemTypes": "Season",
            "SortOrder": "Ascending",
            "Fields": "Genres,Overview,People,CommunityRating"
        ]
        self.get(path, params) { (result) in
            switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(Responses.ItemResponse<[Models.Season]>.self, from: data)
                        self.logger.info("API.getSeasons completed")
                        completion(.success(response.items))
                    } catch let error {
                        self.logger.notice("API.getSeasons ERROR")
                        self.logger.debug("API.getSeasons \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                case .failure(let error): completion(.failure(error))
            }
        }
    }

    /// Retrieves all Episodes for given Series
    /// - Parameters:
    ///   - series_id: Series Item ID
    ///   - completion: Episodes Completion
    public func getEpisodes(for series_id: String, completion: @escaping Completions.Episodes) {
        self.logger.info("API.getEpisodes started")
        self.logger.debug("API.getEpisodes series: \(series_id)")
        let path = "/Shows/\(series_id)/Episodes"
        let params = [
            "userId": self.currentUser?.id ?? "",
            "IncludeItemTypes": "Episode",
            "SortBy": "PremiereDate",
            "SortOrder": "Ascending",
            "Fields": "Genres,Overview,People,CommunityRating,MediaSources"
        ]
        self.get(path, params) { (result) in
            switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(Responses.ItemResponse<[Models.Episode]>.self, from: data)
                        self.logger.info("API.getEpisodes completed")
                        completion(.success(response.items))
                    } catch let error {
                        self.logger.notice("API.getEpisodes ERROR")
                        self.logger.debug("API.getEpisodes \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                case .failure(let error): completion(.failure(error))
            }
        }
    }

    
    // MARK: Get Images
    
    /// Retrieves all Images (Ids) for given Item
    /// - Parameters:
    ///   - item_id: Item ID
    ///   - completion: Images Completion
    public func getImages(for item_id: String, completion: @escaping Completions.Images) {
        self.logger.info("API.getImages started")
        self.logger.debug("API.getImages item: \(item_id)")
        let path = "/Items/\(item_id)/Images"
        self.get(path) { (result) in
            switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode([Models.Image].self, from: data)
                        self.logger.info("API.getImages completed")
                        completion(.success(response))
                    } catch let error {
                        self.logger.notice("API.getImages ERROR")
                        self.logger.debug("API.getImages \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                case .failure(let error): completion(.failure(error))
            }
        }
    }

    // MARK: Search
    
    /// Queries server for items with given Search Term
    /// - Parameters:
    ///   - searchTerm: Search Term String
    ///   - completion: Items Completion
    public func searchItems(_ searchTerm: String, completion: @escaping Completions.Items) {
        self.logger.info("API.searchItems started")
        self.logger.debug("API.searchItems term: \(searchTerm)")
        let path = "/Users/\(currentUser?.id ?? "")/Items"
        let params = [
            "searchTerm": searchTerm,
            "IncludeItemTypes": "Series,Movie",
            "Recursive": String(true),
            "Fields": "Genres",
            "Limit": String(24)
        ]
        self.get(path, params) { (result) in
            switch result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(Responses.ItemResponse<[Models.Item]>.self, from: data)
                        self.logger.info("API.searchItems completed")
                        completion(.success(response.items))
                    } catch let error {
                        self.logger.notice("API.searchItems ERROR")
                        self.logger.debug("API.searchItems \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                case .failure(let error): completion(.failure(error))
            }
        }
    }

    
    /// Queries server for people with given Search Term
    /// - Parameters:
    ///   - searchTerm: Search Term String
    ///   - completion: People Completion
    public func searchPeople(_ searchTerm: String, completion: @escaping Completions.People) {
        self.logger.info("API.searchPeople started")
        self.logger.debug("API.searchPeople term: \(searchTerm)")
        let path = "/Persons"
        let params = [
            "searchTerm": searchTerm,
            "IncludeTypes": "Person",
            "Recursive": String(true),
            "Limit": String(24)
        ]
        self.get(path, params) { (result) in
            switch result {
                case .success(let data):
                    do {
                        self.logger.info("API.searchPeople completed")
                        let response = try JSONDecoder().decode(Responses.ItemResponse<[Models.Person]>.self, from: data)
                        completion(.success(response.items))
                    } catch let error {
                        self.logger.notice("API.searchPeople ERROR")
                        self.logger.debug("API.searchPeople \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                case .failure(let error): completion(.failure(error))
            }
        }
    }

    // MARK: PlaybackStatus
    
    /// Tells the server that playback has started
    /// - Parameters:
    ///   - item_id: Playing Item ID
    ///   - positionTicks: Current Position Ticks
    public func startPlayback(for item_id: String, at positionTicks: Int) {
        self.logger.info("API.startPlayback started")
        self.logger.debug("API.startPlayback item: \(item_id) position: \(positionTicks)")
        let path = "/Sessions/Playing"
        let info = Models.PlaybackInfo.Start(itemId: item_id, positionTicks: positionTicks)
        do {
            let data = try JSONEncoder().encode(info)
            self.post(path, data) { (result) in
                switch result {
                    case .success(_ ):
                        self.logger.info("API.startPlayback completed")
                    case .failure(let error):
                        self.logger.notice("API.startPlayback ERROR")
                        self.logger.debug("API.startPlayback \(error.localizedDescription)")
                }
            }
        } catch let error {
            print(error)
        }
    }

    /// Reports continuing playback to the server
    /// - Parameters:
    ///   - item_id: Playing Item ID
    ///   - positionTicks: Current Position Ticks
    public func reportPlayback(for item_id: String, positionTicks: Int) {
        self.logger.info("API.reportPlayback started")
        self.logger.debug("API.reportPlayback item: \(item_id) position: \(positionTicks)")
        let path = "/Sessions/Playing/Progress"
        let info = Models.PlaybackInfo.Progress(itemId: item_id, positionTicks: positionTicks)
        do {
            let data = try JSONEncoder().encode(info)
            self.post(path, data) { (result) in
                switch result {
                    case .success(_ ):
                        self.logger.info("API.reportPlayback completed")
                    case .failure(let error):
                        self.logger.notice("API.reportPlayback ERROR")
                        self.logger.debug("API.reportPlayback \(error.localizedDescription)")
                }
            }
        } catch let error {
            print("ERROR", error)
        }
    }

    /// Tells the server that playback has stopped
    /// - Parameters:
    ///   - item_id: Playing Item ID
    ///   - positionTicks: end Position Ticks
    public func stopPlayback(for item_id: String, positionTicks: Int) {
        self.logger.info("API.stopPlayback started")
        self.logger.debug("API.stopPlayback item: \(item_id) position: \(positionTicks)")
        let path1 = "/Sessions/Playing/Stop"
        self.post(path1) { (result) in
            switch result {
                case .success(_ ):
                    self.logger.info("API.stopPlayback sessions completed")
                case .failure(let error):
                    self.logger.notice("API.stopPlayback ERROR")
                    self.logger.debug("API.stopPlayback \(error.localizedDescription)")
            }
        }
        let path = "/Videos/ActiveEncodings"
        let params = [
            "DeviceId": self.deviceId
        ]
        let info = Models.PlaybackInfo.Stop(itemId: item_id, positionTicks: positionTicks)
        do {
            let data = try JSONEncoder().encode(info)
            self.delete(path, params, data) { (result) in
                switch result {
                    case .success(_ ):
                        self.logger.info("API.stopPlayback encoding completed")
                    case .failure(let error):
                        self.logger.notice("API.stopPlayback ERROR")
                        self.logger.debug("API.stopPlayback \(error.localizedDescription)")
                }
            }
        } catch let error {
            print(error)
        }
    }


    
    /// Creates URL for Stream of Item and MediaSource
    /// - Parameters:
    ///   - item_id: Item ID (of Media Source)
    ///   - source_id: Media Source
    /// - Returns: URL
    public func getStreamURL(for item_id: String, _ source_id: String) -> URL {
        self.logger.info("API.stopPlayback item: \(item_id) source: \(source_id)")
        let path = "/videos/18f93bce-e588-75f1-5a12-7dc7aa05f041/master.m3u8"
        let params = [
            "DeviceId": self.deviceId,
            "MediaSourceId": "18f93bcee58875f15a127dc7aa05f041",
            "VideoCodec": "h264",
            "AudioCodec": "ac3,mp3,aac",
            "VideoBitrate": "139680000",
            "AudioBitrate": "320000",
            "api_key": "8fd5be7c5b1247b3aad42b884941eac6",
            "TranscodingMaxAudioChannels": "2",
            "RequireAvc": "false",
            "Tag": "c01e1469dd17e2934103b24417a40794",
            "SegmentContainer": "ts",
            "MinSegments": "2",
            "BreakOnNonKeyFrames": "True",
            "h264-profile": "high,main,baseline,constrainedbaseline",
            "h264-level": "51",
            "h264-deinterlace": "true",
            "TranscodeReasons": "ContainerNotSupported,VideoCodecNotSupported,AudioCodecNotSupported"
        ]
        let request = self.makeRequest(path, params)
        let url = request.url!
        return url
    }

    
    /// Returns AVURLAsset for given stream
    /// - Parameters:
    ///   - item_id: Item ID
    ///   - source_id: Media Source ID
    /// - Returns: AVURLAsset for use in VideoPlayer
    public func getPlayerItem(for item_id: String, _ source_id: String) -> AVURLAsset {
        self.logger.info("API.getPlayerItem item: \(item_id) source: \(source_id)")

        let path = "/videos/\(item_id)/master.m3u8"
        let params = [
            "DeviceId": self.deviceId,
            "MediaSourceId": source_id,
            "VideoCodec": "h264",
            "AudioCodec": "ac3,mp3,aac",
            "VideoBitrate": "139680000",
            "AudioBitrate": "320000",
            "TranscodingMaxAudioChannels": "2",
            "RequireAvc": "false",
            "SegmentContainer": "ts",
            "MinSegments": "2",
            "BreakOnNonKeyFrames": "True",
            "h264-profile": "high,main,baseline,constrainedbaseline",
            "h264-level": "51",
            "h264-deinterlace": "true",
            "TranscodeReasons": "ContainerNotSupported,VideoCodecNotSupported,AudioCodecNotSupported"
        ]
        let request = self.makeRequest(path, params)
        let url = request.url!
        let options = ["AVURLAssetHTTPHeaderFieldsKey": request.allHTTPHeaderFields ?? [:]]
        let item = AVURLAsset(url: url, options: options)
        return item
    }

    
    /// Returns the URL for the specified image
    /// - Parameters:
    ///   - id: Item ID
    ///   - type: Image Type
    ///   - maxWidth: Maximum Width of the image
    ///   - quality: Image Quality
    /// - Returns: Image URL
    public func getImageURL(for id: String, _ type: Models.ImageType = .primary, _ maxWidth: Int? = nil, _ quality: Int? = nil) -> URL {
//        self.logger.info("API.getImageURL id: \(id) type: \(type.rawValue) maxWidth: \(maxWidth) quality: \(quality)")
        let path = "/Items/\(id)/Images/\(type.rawValue)"
        let params = [
            "MaxWidth": String(maxWidth ?? 600),
            "Format": "jpg",
            "Quality": String(quality ?? 70)
        ]
        let request = self.makeRequest(path, params)
        let url = request.url!
        return url
    }
}
