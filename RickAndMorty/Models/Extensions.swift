//
//  Extensions.swift
//  RickAndMorty
//
//  Created by Булат Мусин on 06.09.2021.
//

import Foundation
import UIKit

// Для удобства работы с рамками UIView делаем на него расширение
extension UIView{
    
    // Для получения его ширины
    public var width:CGFloat{
        return self.frame.size.width
    }
    
    // Высоты
    public var height:CGFloat{
        return self.frame.size.height
    }
    
    // Верхней грани
    public var top:CGFloat{
        return self.frame.origin.y
    }
    
    // Нижней грани
    public var bottom:CGFloat{
        return self.frame.size.height + self.frame.origin.y
    }
    
    // Левой грани
    public var left:CGFloat{
        return self.frame.origin.x
    }
    
    // Правой грани
    public var right:CGFloat{
        return self.frame.size.width + self.frame.origin.x
    }
}

// Ошибки для Датабейза
enum DatabaseError: Error {
    case failedToGetDataFromMemory
}

//Расширение на строку чтоб можно было локализировать
extension String {
    
    // Получаем язык по умолчанию либо загружаем из UserDefaults
    public static var language: String = {
        // Смотрим в UserDefaults последний использованный язык
        if let lang = DatabaseManager.shared.getLocalization() {
            let path = Bundle.main.path(forResource: lang, ofType: "lproj")
            
            guard let bundle = Bundle(path: path!) else {
                return ""
            }
            // Обновляем пакет с локализацией
            String.bundle = bundle
            return lang
        }
        // Если не нашлось - ставим основной язык системы
        let lang = Bundle.main.preferredLocalizations[0]
        DatabaseManager.shared.setLocalization(to: lang)
        return lang
    }()
    private static var bundle = Bundle.main

    /// Localizes string using currently chosen language
    func localized() -> String {
        return NSLocalizedString(self, tableName: "Localizable", bundle: String.bundle, value: "**\(self)**", comment: "")
    }
    
    
    /// Changes language to given one ("en" and "ru" currently availible)
    public static func changeLocalization(to language: String) {
        // Сообщаем, какой язык мы используем теперь
        String.language = language
        // Находим путь к пакету с нужной локализацией
        let path = Bundle.main.path(forResource: String.language, ofType: "lproj")
        
        guard let bundle = Bundle(path: path!) else {
            return
        }
        
        // И назначаем его использование
        String.bundle = bundle
        // Сохраняем в UserDefaults наш выбор
        DatabaseManager.shared.setLocalization(to: language)
    }
}
