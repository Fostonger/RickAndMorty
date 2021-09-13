//
//  DatabaseManager.swift
//  RickAndMorty
//
//  Created by Булат Мусин on 06.09.2021.
//

import Foundation
import Network
import UIKit

final class DatabaseManager {
    
    // Декодер и закодер для кэширования
    private let propEncoder = PropertyListEncoder()
    private let propDecoder = PropertyListDecoder()
    // Декодер для распаковки данных из сети
    private let decoder = JSONDecoder()
    
    // Адрес хранилища кэша
    private let storage: URL = {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0]
    }()
    
    // Синглтон для доступа откуда угодно
    static let shared = DatabaseManager()
}

extension DatabaseManager {
    
    // MARK: Data loader, returner and saver
    
    /// Downloads data from given address and returns it with given type while caching it
    // Может скачивать и персонажей, и серии, и локации
    public func getDataFor<T: Codable>(path: String, dataType: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        
        let urlString = "https://rickandmortyapi.com/api/\(path)"
        guard let url = URL(string: urlString) else {
            return
        }
        
        // Если папка character в папке с кэшами не существует, то создаем ее вместе с папкой для картинок
        if !FileManager.default.fileExists(atPath: storage.appendingPathComponent("character").path) {
            do {
                try FileManager.default.createDirectory(atPath: storage.appendingPathComponent("character").path, withIntermediateDirectories: true, attributes: nil)
                try FileManager.default.createDirectory(atPath: storage.appendingPathComponent("episode").path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
            }
        }
        
        // Если запрашиваемый файл есть в кэше, декодим и возвращаем его
        if FileManager.default.fileExists(atPath: storage.appendingPathComponent(path + ".data").path) {
            do {
                let cachedPerson = try Data(contentsOf: storage.appendingPathComponent(path + ".data"))
                let person = try self.propDecoder.decode(T.self, from: cachedPerson)
                completion(.success(person))
            }
            catch {
                completion(.failure(error))
            }
        }
        
        // Иначе скачиваем с интернета и кидаем в папку с кэшем
        else {
            URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
                guard let data = data,
                      error == nil,
                      let strongSelf = self else {
                    return
                }
                do {
                    let info = try strongSelf.decoder.decode(T.self, from: data)
                    
                    let property = try strongSelf.propEncoder.encode(info)
                    let storageUrl = strongSelf.storage.appendingPathComponent(path + ".data")
                    try property.write(to: storageUrl, options: .atomic)
                    
                    completion(.success(info))
                }
                catch {
                    completion(.failure(error))
                }
            }.resume()
        }
        
    }
    
    /// Downloads image from given address and returns it with given type while caching it
    // Механизм тот же что и у функции выше
    public func downloadImage(with path: String, completion: @escaping (UIImage?) -> Void) {
        let urlString = "https://rickandmortyapi.com/api/\(path)"
        if !FileManager.default.fileExists(atPath: storage.appendingPathComponent("character/avatar").path) {
            do {
                try FileManager.default.createDirectory(atPath: storage.appendingPathComponent("character/avatar").path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
            }
        }
        
        if FileManager.default.fileExists(atPath: storage.appendingPathComponent(path).path) {
            do {
                let cachedImage = try Data(contentsOf: storage.appendingPathComponent(path))
                let image = try self.propDecoder.decode(Data.self, from: cachedImage)
                completion(UIImage(data: image))
            }
            catch {
                print(error)
                completion(nil)
            }
        }
        else {
            guard let url = URL(string: urlString) else {
                return
            }
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 60)
            URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
                guard error == nil,
                      data != nil,
                      let image = UIImage(data: data!),
                      let strongSelf = self else {
                    return
                }
                
                do {
                    let property = try strongSelf.propEncoder.encode(data)
                    let storageUrl = strongSelf.storage.appendingPathComponent(path)
                    try property.write(to: storageUrl, options: .atomic)
                    
                    completion(image)
                }
                catch {
                    print(error)
                    completion(nil)
                }
                
            }.resume()
        }
    }
    
    /// Erases all cached data
    public func EraseCachedData() {
        // Проверем можно ли удалить папки и удаляем их
        if FileManager.default.isDeletableFile(atPath: storage.appendingPathComponent("character").path) &&
            FileManager.default.isDeletableFile(atPath: storage.appendingPathComponent("episode").path){
            do {
                try FileManager.default.removeItem(at: storage.appendingPathComponent("character"))
                try FileManager.default.removeItem(at: storage.appendingPathComponent("episode"))
                print(storage)
            }
            catch {
                print(error)
            }
        }
    }
    
    
    public func setLocalization(to lang: String) {
        UserDefaults.standard.setValue(lang, forKey: "Localization")
    }
    
    public func getLocalization() -> String? {
        return UserDefaults.standard.string(forKey: "Localization")
    }
}
