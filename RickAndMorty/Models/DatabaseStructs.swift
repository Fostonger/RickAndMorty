//
//  DatabaseStructs.swift
//  RickAndMorty
//
//  Created by Булат Мусин on 09.09.2021.
//

import Foundation

// MARK: СТРУКТУРЫ ДЛЯ РАБОТЫ ДАТАБЕЙЗА
// Копируют структуру JSON на сайте rickandmorty
struct InfoList: Codable {
    let info: Info
}

struct Info: Codable {
    let count: Int
}

struct Episode: Codable {
    var name: String
}

struct Location: Codable {
    var name: String
    let url: String
}

struct Person: Codable {
    let id: Int
    var name: String
    let status: String
    let location: Location
    let image: String
    let episode: [String]
    let url: String
}

