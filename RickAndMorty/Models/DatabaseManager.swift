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
    
    // Словарь на случай офлайн режима, тут будем держать кэшированные данные
    // В ключ даем url адрес, в значение - что должен был бы скачать
    private var dataDict = [String: Data]()
    private var cachedPersonCount = 0
    
    // Адрес хранилища кэша
    private let storage: URL = {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0]
    }()
    
    // Для проверки сети создаем объект класса NWPathMonitor
    private let monitor = NWPathMonitor()
    private var isOnline = false
    // Выделяем для монитора отдельный поток
    let queue = DispatchQueue(label: "Monitor")
    
    init() {
        // Делегат для постоянной проверки сети
        //
        monitor.pathUpdateHandler = { [weak self] path in
            guard let strongSelf = self else {
                return
            }
            if path.status == .satisfied {
                strongSelf.isOnline = true
                NotificationCenter.default.post(name: Notification.Name("Online"), object: nil)
            }
            else {
                strongSelf.isOnline = false
                do{ // Считаем сколько всего файлов в кэше персонажей
                    let personsCount = try FileManager.default.contentsOfDirectory(at: strongSelf.storage.appendingPathComponent("character"),
                                                                                   includingPropertiesForKeys: nil,
                                                                                   options: .skipsHiddenFiles).count
                    // Отнимаем один - это папка с картинками
                    strongSelf.cachedPersonCount = personsCount - 1
                }
                catch {
                    print(error)
                }
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name("Offline"), object: nil)
                }
            }
        }
        monitor.start(queue: queue)
    }
    
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
        // Асинхронно загружаем персонажей
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            // Если папка character в папке с кэшами не существует, то создаем ее вместе с папкой для серий
            if !FileManager.default.fileExists(atPath: strongSelf.storage.appendingPathComponent("character").path) {
                do {
                    try FileManager.default.createDirectory(atPath: strongSelf.storage.appendingPathComponent("character").path, withIntermediateDirectories: true, attributes: nil)
                    try FileManager.default.createDirectory(atPath: strongSelf.storage.appendingPathComponent("episode").path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print(error)
                }
            }
            
            if strongSelf.isOnline {
                // Если запрашиваемый файл есть в кэше, декодим и возвращаем его
                if FileManager.default.fileExists(atPath: strongSelf.storage.appendingPathComponent(path + ".data").path) {
                    do {
                        let cachedData = try Data(contentsOf: strongSelf.storage.appendingPathComponent(path + ".data"))
                        let data = try strongSelf.propDecoder.decode(T.self, from: cachedData)
                        completion(.success(data))
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
            // Если не онлайн, то ищем скачанного персонажа
            else {
                // Если данные уже запрашивались, передаем их
                if strongSelf.dataDict.keys.contains(path) {
                    do {
                        guard let data = strongSelf.dataDict[path] else {
                            completion(.failure(DatabaseError.failedToGetDataFromMemory))
                            return
                        }
                        let info = try strongSelf.propDecoder.decode(T.self, from: data)
                        completion(.success(info))
                    }
                    catch {
                        print(error)
                    }
                }
                // Берем данные из кэша
                else {
                    if (T.self == InfoList.self) {
                        return completion(.success(InfoList(info: Info(count: strongSelf.cachedPersonCount)) as! T))
                    }
                    // Проходим по кэшу и ищем данные
                    let cachedDataPath = strongSelf.storage.appendingPathComponent(path + ".data")
                    if FileManager.default.fileExists(atPath: cachedDataPath.path, isDirectory: .none) {
                        do {
                            let cachedData = try Data(contentsOf: cachedDataPath)
                            let data = try strongSelf.propDecoder.decode(T.self, from: cachedData)
                            let contains = strongSelf.dataDict.contains { (_,v) -> Bool in
                                return v == cachedData
                            }
                            if !contains{
                                strongSelf.dataDict[path] = cachedData
                                completion(.success(data))
                                return
                            }
                        }
                        catch {
                            completion(.failure(error))
                            return
                        }
                    }
                }
            }
            
        }
    }
    
    // Механизм тот же что и у функции выше
    // Не проверяем на случай оффлайна ибо кэшированные персонажи не будут запрашивать не кэшированные аватары
    /// Downloads image from given address and returns it with given type while caching it
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
    
    // Для сохранения последней локализации
    /// Sets new localization to UserDefaults. Choose one from enum
    public func setLocalization(to lang: String.localization) {
        UserDefaults.standard.setValue(lang.rawValue, forKey: "Localization")
    }
    
    // Для получения последней локализации
    /// Gets localization as a String from UserDefaults
    public func getLocalization() -> String? {
        return UserDefaults.standard.string(forKey: "Localization")
    }
}
