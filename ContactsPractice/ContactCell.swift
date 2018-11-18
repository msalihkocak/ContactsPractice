//
//  ContactCell.swift
//  ContactsPractice
//
//  Created by Mehmet Salih Koçak on 18.11.2018.
//  Copyright © 2018 Mehmet Salih Koçak. All rights reserved.
//

import UIKit

class ContactCell: UITableViewCell {
    
    weak var link: ViewController?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        let starButton = UIButton(type: .system)
        starButton.setImage(#imageLiteral(resourceName: "fav_star"), for: .normal)
        starButton.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        
        starButton.tintColor = .orange
        starButton.addTarget(self, action: #selector(handleStarTapped), for: .touchUpInside)
        
        accessoryView = starButton
    }
    
    @objc func handleStarTapped(){
        link?.starTapped(for: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
