//
//  ViewController.swift
//  RickAndMorty
//
//  Created by Булат Мусин on 06.09.2021.
//

import UIKit

class ListViewController: UIViewController {

    // characters count берем из интернета
    private var charactersCount = 0
    // characters будем заполнять по ходу скроллинга таблицы
    lazy private var characters = [Person?](repeating: nil, count: charactersCount)
    
    private let listOfCharacters: UITableView = {
        let list = UITableView()
        list.register(CharacterTableViewCell.self, forCellReuseIdentifier: CharacterTableViewCell.identifier)
        return list
    }()
    
    // Слушает
    private var internetObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Запрашиваем в начале общее кол-во персонажей
        DatabaseManager.shared.getDataFor(path: "character/", dataType: InfoList.self, completion: { [weak self] result in
            switch result{
            case .success(let info):
                self?.charactersCount = info.info.count
            case .failure(let error):
                print(error)
            }
            DispatchQueue.main.async {
                
                self?.listOfCharacters.reloadData()
            }
        })
        
        view.addSubview(listOfCharacters)
        setupListOfCharacters()
        
        // Настройка navigation bar
        navigationItem.title = "characters".localized()
        navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .refresh,
                                                              target: self,
                                                              action: #selector(didTapRefreshButton)),
                                              UIBarButtonItem(title: String.language.localized(),
                                                              style: .plain,
                                                              target: self,
                                                              action: #selector(didTapChangeLanguageButton))]
        internetObserver = NotificationCenter.default.addObserver(forName: Notification.Name("Offline"), object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            for index in 0 ..< strongSelf.charactersCount {
                strongSelf.characters[index] = nil
            }
            // И количество, чтобы потом все загрузить заново
            strongSelf.charactersCount = 0
            strongSelf.listOfCharacters.reloadData()
            
            // И запрашиваем все заново
            DatabaseManager.shared.getDataFor(path: "character/", dataType: InfoList.self, completion: { [weak self] result in
                switch result{
                case .success(let info):
                    self?.charactersCount = info.info.count
                case .failure(let error):
                    print(error)
                }
                DispatchQueue.main.async {
                    
                    self?.listOfCharacters.reloadData()
                }
            })
        })
    }
    
    /// Switches between russian and english languages
    @objc func didTapChangeLanguageButton() {
        // Меняем на следующий язык локализацию
        if String.language == "en" {
            String.changeLocalization(to: "ru")
        }
        else {
            String.changeLocalization(to: "en")
        }
        // обновляем таблицу
        listOfCharacters.reloadData()
        // обновляем navigation bar
        navigationItem.title = "characters".localized()
        navigationItem.rightBarButtonItems?[1] = UIBarButtonItem(title: String.language.localized(),
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(didTapChangeLanguageButton))
    }
    
    /// Deletes all cached data
    @objc func didTapRefreshButton() {
        // Показываем локализованное предупреждение
        let alert = UIAlertController(title: "sure_to_refresh_table_question".localized(),
                                      message: "sure_to_refresh_table_description".localized(),
                                      preferredStyle: .alert)
        // Кнопка подтверждения
        alert.addAction(UIAlertAction(title: "confirm_refreshing".localized(),
                                      style: .destructive,
                                      handler: { [weak self] _ in
                                        guard let strongSelf = self else {
                                            return
                                        }
                                        
                                        // Стираем все из папки кэша
                                        DatabaseManager.shared.EraseCachedData()
                                        
                                        // Зачищаем массив персонажей
                                        for index in 0 ..< strongSelf.charactersCount {
                                            strongSelf.characters[index] = nil
                                        }
                                        // И количество, чтобы потом все загрузить заново
                                        strongSelf.charactersCount = 0
                                        strongSelf.listOfCharacters.reloadData()
                                        
                                        // И запрашиваем все заново
                                        DatabaseManager.shared.getDataFor(path: "character/", dataType: InfoList.self, completion: { [weak self] result in
                                            switch result{
                                            case .success(let info):
                                                self?.charactersCount = info.info.count
                                            case .failure(let error):
                                                print(error)
                                            }
                                            DispatchQueue.main.async {
                                                
                                                self?.listOfCharacters.reloadData()
                                            }
                                        })
                                      }))
        // Кнопка отмены
        alert.addAction(UIAlertAction(title: "cancel_refreshing".localized(),
                                      style: .cancel,
                                      handler: nil))
        present(alert, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.backgroundColor = .systemBackground
        listOfCharacters.frame = view.safeAreaLayoutGuide.layoutFrame
    }

    // Настраиваем список персонажей
    private func setupListOfCharacters() {
        listOfCharacters.delegate = self
        listOfCharacters.dataSource = self
        listOfCharacters.prefetchDataSource = self
    }

}

extension ListViewController: UITableViewDelegate, UITableViewDataSource {
    
    // Если выбрали ячейку
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Снимаем выделение
        tableView.deselectRow(at: indexPath, animated: true)
        guard let choosedPerson = characters[indexPath.row] else {
            return
        }
        // Создаем объект класса окна с деталями персонажа
        // Передаем туда того, кого  будем показывать
        let vc = PersonDetailsViewController(with: choosedPerson)
        // В оглавление ставим его имя
        vc.title = choosedPerson.name
        vc.navigationItem.largeTitleDisplayMode = .always
        // Пушим окно
        navigationController?.pushViewController(vc, animated: true)
        // Запускаем процесс конфигурации,  пусть качает и получает что нужно
        vc.config()
    }
    
    // Задаем количество ячеек - общее количество персонажей
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return charactersCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Достаем ячейку для настройки
        let cell = listOfCharacters.dequeueReusableCell(withIdentifier: CharacterTableViewCell.identifier,
                                                        for: indexPath) as! CharacterTableViewCell
        // Если уже запрашивали у датабейза данные персонажа,
        // Конфигурируем ячейку используя эти данные
        if let character = characters[indexPath.row] {
            cell.configure(with: character)
        }
        // Иначе запрашиваем у датабейза персонажа по заданному адресу
        // Сюда заходит только для первых ячеек, дальше данные грузятся через prefetch
        else {
            DatabaseManager.shared.getDataFor(path: "character/\(indexPath.row + 1)",
                                              dataType: Person.self,
                                              completion: { [weak self] result in
                                                
                switch result{
                case .success(let person):
                    // Скаченного персонажа сохраняем в общий массив
                    self?.characters[indexPath.row] = person
                    // На главном потоке обновляем ячейку
                    // Там она сконфигурируется методом cell.configure()
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
    
    // ФИксируем высоту ячейки
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}

// Расширение для заблаговременной загрузки персонажей,
// До того как они появились на tableView
extension ListViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        
        for indexPath in indexPaths {
            // Обращаемся к датабейзу и загружаем персонажей
            guard let _ = self.characters[indexPath.row] else {
                DatabaseManager.shared.getDataFor(path: "character/\(indexPath.row + 1)", dataType: Person.self, completion: { [weak self] result in
                    
                    switch result{
                    case .success(let person):
                        self?.characters[indexPath.row] = person
                        DatabaseManager.shared.downloadImage(with: person.image.cutOff(offset: 32), completion: { _ in })
                    case .failure(let error):
                        print(error)
                    }
                })
                return
            }
        }
    }
}

