//
//  DatabaseManager.swift
//  RickAndMorty
//
//  Created by Булат Мусин on 06.09.2021.
//

import Foundation
import UIKit

struct InfoList: Codable {
    let info: Info
}

struct Info: Codable {
    let count: Int
}

struct Episode: Codable {
    let name: String
}

struct Location: Codable {
    let name: String
    let url: String
}

struct Person: Codable {
    let id: Int
    let name: String
    let status: String
    let location: Location
    let image: String
    let episode: [String]
    let url: String
}

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
}

extension DatabaseManager {
    
    public func getDataFor<T: Codable>(path: String, dataType: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        let urlString = "https://rickandmortyapi.com/api/\(path)"
        guard let url = URL(string: urlString) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) {(data, response, error) in
            
            guard let data = data,
                  error == nil else {
                return
            }
            
            do {
                let info = try JSONDecoder().decode(T.self, from: data)
                completion(.success(info))
            }
            catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    public func downloadImage(with urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            return
        }
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 60)
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard error == nil,
                  data != nil else {
                return
            }
            guard let image = UIImage(data: data!) else {
                return
            }
            DispatchQueue.main.async {
                completion(image)
            }
            
        }.resume()
    }
}
