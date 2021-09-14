//
//  CharacterTableViewCell.swift
//  RickAndMorty
//
//  Created by Булат Мусин on 06.09.2021.
//

import UIKit

// Класс ячейки персонажа для tableView
class CharacterTableViewCell: UITableViewCell {
    
    // Идентефикатор ячеек
    static let identifier = "CharacterTableViewCell"
    
    // Место для аватара
    private let avatarImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.layer.cornerRadius = 35
        image.layer.masksToBounds = true
        return image
    }()
    
    // Место для имени
    private let nameLabel: UILabel = {
        let name = UILabel()
        name.font = .systemFont(ofSize: 17, weight: .heavy)
        name.translatesAutoresizingMaskIntoConstraints = false
        return name
    }()
    
    // Место для статуса
    private let statusLabel: UILabel = {
        let status = UILabel()
        status.font = .systemFont(ofSize: 16, weight: .medium)
        status.textAlignment = .center
        return status
    }()
    
    // Для красоты добавил картинку местоположения
    private let locationImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.layer.masksToBounds = true
        return image
    }()
    
    // Место для последнего известного местоположения
    private let lastLocationLabel: UILabel = {
        let loc = UILabel()
        loc.font = .systemFont(ofSize: 16, weight: .light)
        loc.adjustsFontSizeToFitWidth = true
        return loc
    }()
    
    // Опять же для красоты картинка серии
    private let episodeImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.layer.masksToBounds = true
        return image
    }()
    
    // Место для названия первой серии, в которой появился персонаж
    private let firstEpisodeLabel: UILabel = {
        let ep = UILabel()
        ep.font = .systemFont(ofSize: 16, weight: .light)
        ep.adjustsFontSizeToFitWidth = true
        return ep
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(locationImageView)
        contentView.addSubview(episodeImageView)
        contentView.addSubview(lastLocationLabel)
        contentView.addSubview(firstEpisodeLabel)
        // Назначаем якоря, чтоб имя красиво выводилось
        // И если что переносилось на новую строку
        let constraints = [
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 90),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -100),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: 60)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Фиксируем аватарку
        avatarImageView.frame = CGRect(x: 10,
                                       y: 10,
                                       width: 70,
                                       height: 70)
        
        // Ставим огранияение на строки у имени (3 строки уже не умещаются)
        nameLabel.numberOfLines = 2
        
        // Фиксируем место статуса
        statusLabel.frame = CGRect(x: nameLabel.right + 10,
                                   y: 10,
                                   width: 90,
                                   height: 16)
        
        // Фиксируем картинку локации
        locationImageView.frame = CGRect(x: avatarImageView.right + 10,
                                         y: 60,
                                         width: 20,
                                         height: 20)
        
        // Фиксируем место локации
        lastLocationLabel.frame = CGRect(x: locationImageView.right + 10,
                                         y: 60,
                                         width: contentView.width - 60 - avatarImageView.right,
                                         height: 20)
        
        // Фиксируем картинку серии
        episodeImageView.frame = CGRect(x: avatarImageView.right + 10,
                                        y: 90,
                                        width: 20,
                                        height: 20)
        
        // Фиксируем место серии
        firstEpisodeLabel.frame = CGRect(x: episodeImageView.right + 10,
                                         y: 90,
                                         width: contentView.width - 60 - avatarImageView.right,
                                         height: 20)
    }
    
    /// Configures cell with given character
    public func configure(with model: Person) {
        // Вписываем имя персонажа
        self.nameLabel.text = model.name
        // Вписываем статус (локализованный)
        self.statusLabel.text = model.status.localized()
        // В зависимости от статуса меняем цвет статуса
        switch model.status {
        case "Alive":
            // Жив - зеленый
            self.statusLabel.textColor = .systemGreen
        case "Dead":
            // Мертв - красный
            self.statusLabel.textColor = .systemRed
        default:
            // Неизвестен - серый
            self.statusLabel.textColor = .systemGray
        }
        // Настраиваем визуал локации
        self.lastLocationLabel.text = model.location.name
        locationImageView.image = UIImage(systemName: "map")
        // Настраиваем картинку серии
        episodeImageView.image = UIImage(systemName: "play.circle")
        guard !model.episode[0].isEmpty else {
            return
        }
        
        // Запрашиваем у Датабейза название серии, в которой впервые появился персонаж
        DatabaseManager.shared.getDataFor(path: model.episode[0].cutOff(offset: 32), dataType: Episode.self, completion: { [weak self] result in
            switch result {
            case .success(let episode):
                // На основном потоке обновляем название серии
                DispatchQueue.main.async {
                    self?.firstEpisodeLabel.text = episode.name
                }
            case .failure(let error):
                print(error)
            }
        })
        // Запрашиваем у Датабейза картинку
        DatabaseManager.shared.downloadImage(with: model.image.cutOff(offset: 32), completion: { [weak self] image in
            guard let strongSelf = self else {
                return
            }
            // И на основном потоке обновляем аватарку
            DispatchQueue.main.async {
                strongSelf.avatarImageView.image = image
            }
        })
    }

}
