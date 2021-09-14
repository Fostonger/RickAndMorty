//
//  PersonDetailsViewController.swift
//  RickAndMorty
//
//  Created by Булат Мусин on 09.09.2021.
//

import UIKit

class PersonDetailsViewController: UIViewController {
    
    // Тут храним данные о персонаже
    private let person: Person
    
    // Панель на которой все будем рисовать
    private let profileView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Строчка для имени
    private let nameLabel: UILabel = {
        let name = UILabel()
        name.font = .systemFont(ofSize: 19, weight: .medium)
        name.translatesAutoresizingMaskIntoConstraints = false
        name.numberOfLines = 0
        return name
    }()
    
    // Строчка для статуса
    private let statusLabel: UILabel = {
        let status = UILabel()
        status.font = .systemFont(ofSize: 17, weight: .medium)
        status.numberOfLines = 2
        status.layer.masksToBounds = true
        status.layer.cornerRadius = 8
        status.textAlignment =  .center
        status.textColor = .systemGray6
        status.translatesAutoresizingMaskIntoConstraints = false
        return status
    }()
    
    // Строчка для полседнего известного местоположения
    private let locationLabel: UILabel = {
        let loc = UILabel()
        loc.font = .systemFont(ofSize: 18, weight: .light)
        loc.numberOfLines = 0
        loc.lineBreakStrategy = .hangulWordPriority
        loc.translatesAutoresizingMaskIntoConstraints = false
        return loc
    }()
    
    // Строчка для первой серии, в которой персонаж появился
    private let episodeLabel: UILabel = {
        let ep = UILabel()
        ep.font = .systemFont(ofSize: 18, weight: .light)
        ep.numberOfLines = 0
        ep.lineBreakStrategy = .hangulWordPriority
        ep.translatesAutoresizingMaskIntoConstraints = false
        return ep
    }()
    
    // Место для аватара
    private let avatarImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.layer.cornerRadius = 15
        image.layer.masksToBounds = true
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    init(with person: Person) {
        self.person = person
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(profileView)
        profileView.addSubview(avatarImageView)
        profileView.addSubview(nameLabel)
        profileView.addSubview(statusLabel)
        profileView.addSubview(locationLabel)
        profileView.addSubview(episodeLabel)
        
        // Закрепляем якоря, чтоб текст можно было без проблем на другую строку сносить
        let constraints = [
            profileView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            profileView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            profileView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            profileView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            avatarImageView.topAnchor.constraint(equalTo: profileView.topAnchor, constant: 10),
            avatarImageView.leadingAnchor.constraint(equalTo: profileView.leadingAnchor, constant: 10),
            avatarImageView.trailingAnchor.constraint(equalTo: statusLabel.trailingAnchor, constant: -90),
            
            statusLabel.topAnchor.constraint(equalTo: profileView.topAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 10),
            statusLabel.trailingAnchor.constraint(equalTo: profileView.trailingAnchor, constant: -10),
            
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: profileView.leadingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: profileView.trailingAnchor, constant: -10),
            
            locationLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            locationLabel.leadingAnchor.constraint(equalTo: profileView.leadingAnchor, constant: 10),
            locationLabel.trailingAnchor.constraint(equalTo: profileView.trailingAnchor, constant: -10),
            
            episodeLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 5),
            episodeLabel.leadingAnchor.constraint(equalTo: profileView.leadingAnchor, constant: 10),
            episodeLabel.trailingAnchor.constraint(equalTo: profileView.trailingAnchor, constant: -10)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileView.frame = view.safeAreaLayoutGuide.layoutFrame
        view.backgroundColor = .systemBackground
    }
    
    /// Configures view with given to constructor character
    public func config() {
        // Задаем имя
        nameLabel.text = "name".localized() + person.name
        // В зависимости от статуса меняем подбой текста
        switch person.status {
        case "Alive":
            // Если жив - зеленый
            statusLabel.backgroundColor = .systemGreen
        case "Dead":
            // Мертв - красный
            statusLabel.backgroundColor = .systemRed
        default:
            // Неизвестен - серый
            statusLabel.backgroundColor = .systemGray
        }
        // Выводим текст статуса
        statusLabel.text = "status".localized() + person.status.localized()
        // Вывод последнего известного местоположения
        locationLabel.text = "last_known_location".localized() + person.location.name
        
        guard !person.episode[0].isEmpty else {
            return
        }
        
        // Запрашиваем у Датабейза информацию о серии
        DatabaseManager.shared.getDataFor(path: person.episode[0].cutOff(offset: 32), dataType: Episode.self, completion: { [weak self] result in
            switch result {
            case .success(let episode):
                DispatchQueue.main.async {
                    // Пишем в label название серии в основном потоке
                    self?.episodeLabel.text = "first_seen_in".localized() + episode.name
                }
            case .failure(let error):
                print(error)
            }
        })
        
        // Запрашиваем картинку у Датабейза
        DatabaseManager.shared.downloadImage(with: person.image.cutOff(offset: 32), completion: { [weak self] image in
            guard let strongSelf = self else {
                return
            }
            // И в основном потоке обновляем картинку персонажа
            DispatchQueue.main.async {
                strongSelf.avatarImageView.image = image
            }
        })
    }
}
