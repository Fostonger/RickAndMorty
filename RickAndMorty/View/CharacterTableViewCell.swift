//
//  CharacterTableViewCell.swift
//  RickAndMorty
//
//  Created by Булат Мусин on 06.09.2021.
//

import UIKit

class CharacterTableViewCell: UITableViewCell {
    
    static let identifier = "CharacterTableViewCell"
    
    private let avatarImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.layer.cornerRadius = 35
        image.layer.masksToBounds = true
        return image
    }()
    
    private let nameLabel: UILabel = {
        let name = UILabel()
        name.font = .systemFont(ofSize: 18, weight: .heavy)
        name.translatesAutoresizingMaskIntoConstraints = false
        return name
    }()
    
    private let statusLabel: UILabel = {
        let status = UILabel()
        status.font = .systemFont(ofSize: 16, weight: .medium)
        status.textAlignment = .center
        return status
    }()
    
    private let locationImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.layer.masksToBounds = true
        return image
    }()
    
    private let lastLocationLabel: UILabel = {
        let loc = UILabel()
        loc.font = .systemFont(ofSize: 16, weight: .light)
        return loc
    }()
    
    private let episodeImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.layer.masksToBounds = true
        return image
    }()
    
    private let firstEpisodeLabel: UILabel = {
        let ep = UILabel()
        ep.font = .systemFont(ofSize: 16, weight: .light)
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
        let constraints = [
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 90),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -100)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        avatarImageView.frame = CGRect(x: 10,
                                       y: 10,
                                       width: 70,
                                       height: 70)
//        nameLabel.frame = CGRect(x: avatarImageView.right + 10,
//                                 y: 10,
//                                 width: contentView.width - 120 - avatarImageView.width,
//                                 height: 60)
        nameLabel.numberOfLines = 0
        statusLabel.frame = CGRect(x: nameLabel.right + 10,
                                   y: 10,
                                   width: 90,
                                   height: 30)
        locationImageView.frame = CGRect(x: avatarImageView.right + 10,
                                         y: 60,
                                         width: 20,
                                         height: 20)
        
        lastLocationLabel.frame = CGRect(x: locationImageView.right + 10,
                                         y: 60,
                                         width: contentView.width - 40 - avatarImageView.width,
                                         height: 20)
        
        episodeImageView.frame = CGRect(x: avatarImageView.right + 10,
                                        y: 90,
                                        width: 20,
                                        height: 20)
        
        firstEpisodeLabel.frame = CGRect(x: episodeImageView.right + 10,
                                         y: 90,
                                         width: contentView.width - 40 - avatarImageView.width,
                                         height: 20)
    }
    
    public func configure(with model: Person) {
        self.nameLabel.text = model.name
        self.statusLabel.text = model.status
        switch model.status {
        case "Alive":
            self.statusLabel.textColor = .systemGreen
        case "Dead":
            self.statusLabel.textColor = .systemRed
        default:
            self.statusLabel.textColor = .systemGray
        }
        self.lastLocationLabel.text = model.location.name
        locationImageView.image = UIImage(systemName: "map")
        episodeImageView.image = UIImage(systemName: "play.circle")
        guard !model.episode[0].isEmpty else {
            return
        }
        let cutIndex = model.episode[0].index(model.episode[0].startIndex, offsetBy: 32)
        let path = model.episode[0][cutIndex...]
        DatabaseManager.shared.getDataFor(path: String(path), dataType: Episode.self, completion: { [weak self] result in
            switch result {
            case .success(let episode):
                DispatchQueue.main.async {
                    self?.firstEpisodeLabel.text = episode.name
                }
            case .failure(let error):
                print(error)
            }
        })
        DatabaseManager.shared.downloadImage(with: model.image, completion: { [weak self] image in
            guard let strongSelf = self else {
                return
            }
            strongSelf.avatarImageView.image = image
        })
    }

}
