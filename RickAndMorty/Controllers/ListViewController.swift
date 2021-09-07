//
//  ViewController.swift
//  RickAndMorty
//
//  Created by Булат Мусин on 06.09.2021.
//

import UIKit

class ListViewController: UIViewController {

    private var charactersCount = 0
    lazy private var characters:[Person?] = [Person?](repeating: nil, count: 671)
    
    private let listOfCharacters: UITableView = {
        let list = UITableView()
        list.register(CharacterTableViewCell.self, forCellReuseIdentifier: CharacterTableViewCell.identifier)
        return list
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DatabaseManager.shared.getDataFor(path: "character/",
                                          dataType: InfoList.self,
                                          completion: { [weak self] result in
            switch result{
            case .success(let info):
                self?.charactersCount = info.info.count
            case .failure(let error):
                print(error)
            }
        })
        
        view.addSubview(listOfCharacters)
        setupListOfCharacters()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        listOfCharacters.frame = view.bounds
    }

    private func setupListOfCharacters() {
        listOfCharacters.delegate = self
        listOfCharacters.dataSource = self
        listOfCharacters.prefetchDataSource = self
    }

}

extension ListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 671
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = listOfCharacters.dequeueReusableCell(withIdentifier: CharacterTableViewCell.identifier,
                                                        for: indexPath) as! CharacterTableViewCell
        if let character = characters[indexPath.row] {
            print("configuring \(indexPath.row)")
            cell.configure(with: character)
        }
        else {
            print("else sataement \(indexPath.row)")
            DatabaseManager.shared.getDataFor(path: "character/\(indexPath.row + 1)",
                                              dataType: Person.self,
                                              completion: { [weak self] result in
                                                
                switch result{
                case .success(let person):
                    self?.characters[indexPath.row] = person
                    if person.name == "Rick Sanchez"{
                        print(indexPath.row)
                    }
                    DispatchQueue.main.async {
                        self?.listOfCharacters.reloadRows(at: [indexPath], with: .none)
                    }
                case .failure(let error):
                    print(error)
                }
            })
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}

extension ListViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            print("prefetching \(indexPath.row)")
            guard let _ = self.characters[indexPath.row] else {
            DatabaseManager.shared.getDataFor(path: "character/\(indexPath.row)",
                                              dataType: Person.self,
                                              completion: { [weak self] result in
                                                
                switch result{
                case .success(let person):
                    self?.characters[indexPath.row] = person
                case .failure(let error):
                    print(error)
                }
                                                
                })
                return
            }
        }
    }
    
}

