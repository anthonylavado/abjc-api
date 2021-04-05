//
//  ArtworkFetcher.swift
//  
//
//  Created by Noah Kamara on 15.03.21.
//

import Foundation


class ArtworkFetcher {
    private static func apiURL(_ locale: String = "en-gb", _ query: String) -> URL {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "uts-api.itunes.apple.com"
        urlComponents.path = "/uts/v2/search/incremental"
            
        urlComponents.queryItems = [
            URLQueryItem(name: "sf", value: "143443"),
            URLQueryItem(name: "locale", value: locale),
            URLQueryItem(name: "caller", value: "wta"),
            URLQueryItem(name: "utsk", value: "78dc2e4609ba5f1::::::736f5ba8c12ed90"),
            URLQueryItem(name: "v", value: "34"),
            URLQueryItem(name: "pfm", value: "desktop"),
            URLQueryItem(name: "q", value: query)
            
        ]
            
        return urlComponents.url!
    }
    
    
    private static func queryAPI(for title: String, in locale: String = "en-gb", completion: @escaping (Result<[ArtworkQueryResponse.Item], Error>) -> Void) {
        let url = apiURL(locale, title)
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(FetchError.internetConnection))
            }
            
            if let data = data {
                do {
                    let res = try JSONDecoder().decode(ArtworkQueryResponse.self, from: data)
                    let items = res.data.canvas.shelves.flatMap({ $0.items })
                    completion(.success(items))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    public static func fetchArtwork(for title: String, in locale: String = "en-gb", completion: @escaping (Result<ArtworkObject, Error>) -> Void) {
        queryAPI(for: title, in: locale) { (result) in
            switch result {
                case .failure(let error): completion(.failure(error))
                case .success(let items):
                    if items.count == 0 {
                        completion(.failure(FetchError.noMatch))
                    } else if items.count == 1 {
                        completion(.success(items.first!.toModel()))
                    } else {
                        completion(.success(items.first!.toModel()))
                    }
            }
        }
    }
}

extension ArtworkFetcher {
    enum FetchError: Error {
        case internetConnection
        case noMatch
    }
    
    class ArtworkObject {
        let cover: ArtworkURL
        let logo: ArtworkURL?
        
        init(cover: ArtworkURL, logo: ArtworkURL? = nil) {
            self.cover = cover
            self.logo = logo
        }
        
        class ArtworkURL {
            let baseURL: URL
            
            func url(_ width: Int, _ height: Int) -> URL {
                var urlComponents = URLComponents(url: self.baseURL, resolvingAgainstBaseURL: false)!
                urlComponents.path.append("/" + String(width) + "x" + String(height) + ".jpeg")
                return urlComponents.url!
            }
            
            init(_ url: String) {
                print(url)
                let string = url.replacingOccurrences(of: "/{w}x{h}.{f}", with: "")
                self.baseURL = URL(string: string)!
            }
        }
    }
}
extension ArtworkFetcher {
    struct ArtworkQueryResponse: Codable {
        let data: DataClass
        let utsk: String
        
        struct DataClass: Codable {
            let q: String
            let canvas: Canvas
        }
        
        struct Canvas: Codable {
            let id, type, title: String
            let nextToken: String?
            let shelves: [Shelf]
        }
        
        // MARK: - Shelf
        struct Shelf: Codable {
            let title, id: String
            let items: [Item]
        }
        
        // MARK: - Item
        struct Item: Codable {
            let id: String
            let type: MediaType
            let title: String
            let images: Images
            let releaseDate: Int?
            let duration: Int?
            
            public func toModel() -> ArtworkObject {
                let cover = ArtworkObject.ArtworkURL(images.coverArt16X9.url)
//                if images.contentLogo != nil {
//                    let logo = ArtworkObject.ArtworkURL(images.contentLogo!.url)
//                    return ArtworkObject(cover: cover, logo: logo)
//                }
                return ArtworkObject(cover: cover)
            }
        }
        
        struct Images: Codable {
            let coverArt: ImageContainer
            let previewFrame: ImageContainer?
            let fullColorContentLogo: ImageContainer?
            let centeredFullScreenBackgroundImage: ImageContainer?
            let centeredFullScreenBackgroundSmallImage: ImageContainer?
            let coverArt16X9: ImageContainer
            let singleColorContentLogo: ImageContainer?
            let fullScreenBackground: ImageContainer?
            let bannerUberImage: ImageContainer?
            let contentLogo: ImageContainer?
        }
        
        
        // MARK: - BannerUberImage
        struct ImageContainer: Codable {
            let width, height: Int
            let url: String
            let joeColor: String?
            let supportsLayeredImage, isP3: Bool?
        }
        
        enum MediaType: String, Codable {
            case movie = "Movie"
            case movieBundle = "MovieBundle"
            case show = "Show"
            
            var jellyfinType: API.Models.MediaType {
                switch self {
                    case .movie: return .movie
                    case .show: return .series
                    default: return .movie
                }
            }
        }
    }
}






