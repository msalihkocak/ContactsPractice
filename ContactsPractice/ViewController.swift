//
//  ViewController.swift
//  ContactsPractice
//
//  Created by Mehmet Salih Koçak on 18.11.2018.
//  Copyright © 2018 Mehmet Salih Koçak. All rights reserved.
//

import UIKit
import Contacts

let cellId = "cellId"

class ViewController: UITableViewController {
    
    var listOfContacts = [[LocalContact]]()
    var sectionHeaders = [SectionHeader]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Contacts"
        navigationController?.navigationBar.barTintColor = .navBar
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.largeTitleTextAttributes = textAttributes
        
        tableView.backgroundColor = .white
        
        let item = UIBarButtonItem(title: "Show/Hide", style: .plain, target: self, action: #selector(showHideButtonTapped))
        item.tintColor = .white
        navigationItem.rightBarButtonItem = item
        
        tableView.register(ContactCell.self, forCellReuseIdentifier: cellId)
        fillDataSource()
    }
    
    var isIndexPathsShowing = false
    
    @objc func showHideButtonTapped(){
        var indexPathsToReload = [IndexPath]()
        for section in listOfContacts.indices{
            if sectionHeaders[section].isOpened{
                for row in listOfContacts[section].indices{
                    indexPathsToReload.append(IndexPath(row: row, section: section))
                }
            }
        }
        isIndexPathsShowing = !isIndexPathsShowing
        tableView.reloadRows(at: indexPathsToReload, with: isIndexPathsShowing ? .left : .right)
    }
    
    func fillDataSource(){
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { (granted, err) in
            if let error = err{
                print("Failed to read contacts", error.localizedDescription)
                return
            }
            if granted{
                print("Access granted.")
                
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
                let request = CNContactFetchRequest(keysToFetch: keys)
                var localContacts = [LocalContact]()
                do{
                    try store.enumerateContacts(with: request, usingBlock: { (contact, flag) in
                        let localContact = LocalContact(contact: contact, hasFavorited: false)
                        localContacts.append(localContact)
                    })
                } catch let error{
                    print("Failed to enumarate contacts:", error.localizedDescription)
                }
                localContacts.sort(by: {$0.contact.givenName < $1.contact.givenName})
                self.createSections(from: localContacts)
            }else{
                print("Access failed.")
            }
        }
    }
    
    func createSections(from localContacts:[LocalContact]){
        for localContact in localContacts{
            if let firstCharacterOfContact = localContact.contact.givenName.first{
                var isSectionMatchFoundForCurrentContact = false
                for (index, var list) in listOfContacts.enumerated(){
                    guard let firstElement = list.first?.contact.givenName else{ return }
                    guard let firstCharacter = firstElement.capitalized.first else{ return }
                    if firstCharacter == firstCharacterOfContact{
                        list.append(localContact)
                        listOfContacts[index] = list
                        isSectionMatchFoundForCurrentContact = true
                        break
                    }
                }
                if !isSectionMatchFoundForCurrentContact{
                    let newSection = [localContact]
                    listOfContacts.append(newSection)
                }
            }
        }
        
        for list in listOfContacts{
            guard let firstElement = list.first?.contact.givenName else{ return }
            guard let firstCharacter = firstElement.capitalized.first else{ return }
            let header = SectionHeader(sectionName: "\(firstCharacter)", isOpened: true)
            sectionHeaders.append(header)
        }
        print(listOfContacts)
    }
    
    func starTapped(for cell:ContactCell){
        guard let indexPath = tableView.indexPath(for: cell) else{ return }
        let contact = listOfContacts[indexPath.section][indexPath.row]
        listOfContacts[indexPath.section][indexPath.row].hasFavorited = !contact.hasFavorited
        UIView.transition(with: cell.accessoryView!, duration: 0.1, options: .curveEaseIn, animations: {
            cell.accessoryView?.tintColor = self.listOfContacts[indexPath.section][indexPath.row].hasFavorited ? .orange : .lightGray
        }, completion: nil)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return listOfContacts.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionHeaders[section].isOpened ? listOfContacts[section].count : 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ContactCell
        let localContact = listOfContacts[indexPath.section][indexPath.row]
        cell.textLabel?.text = isIndexPathsShowing ? "\(localContact.contact.givenName) \(localContact.contact.familyName)   Section:\(indexPath.section), Row:\(indexPath.row)" : localContact.contact.givenName + " " + localContact.contact.familyName
        cell.accessoryView?.tintColor = localContact.hasFavorited ? .orange : .lightGray
        cell.detailTextLabel?.text = localContact.contact.phoneNumbers.first?.value.stringValue
        cell.link = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let openOrCloseString = sectionHeaders[section].isOpened ? "Close" : "Open"
        let tableHeaderView = TableHeaderView()
        tableHeaderView.openCloseButton.setTitle(openOrCloseString, for: .normal)
        tableHeaderView.openCloseButton.tag = section
        tableHeaderView.openCloseButton.addTarget(self, action: #selector(toggleOpenCloseSection(_:)), for: .touchUpInside)
        tableHeaderView.headerTitleLabel.text = sectionHeaders[section].sectionName
        return tableHeaderView
    }
    
    @objc func toggleOpenCloseSection(_ sender:UIButton){
        let sectionIndex = sender.tag
        sectionHeaders[sectionIndex].isOpened = !sectionHeaders[sectionIndex].isOpened
        tableView.reloadSections(IndexSet(integer: sectionIndex), with: .fade)
    }
}

struct SectionHeader {
    var sectionName:String
    var isOpened:Bool
}

struct LocalContact {
    var contact:CNContact
    var hasFavorited:Bool
}

extension UIColor{
    static let navBar = UIColor(red: 253/255, green: 92/255, blue: 34/255, alpha: 1.0)
    static let tableHeader = UIColor(red: 253/255, green: 153/255, blue: 39/255, alpha: 1.0)
}

class TableHeaderView:UIView{
    
    let openCloseButton: UIButton = {
        let button = UIButton(type: .system)
        button.contentHorizontalAlignment = .right
        
        button.tintColor = UIColor(white: 0.95, alpha: 1.0)
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let headerTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = .white
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .tableHeader
        
        addSubview(headerTitleLabel)
        [headerTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
         headerTitleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
         headerTitleLabel.heightAnchor.constraint(equalTo: heightAnchor),
         headerTitleLabel.widthAnchor.constraint(equalToConstant: 28)].forEach({$0.isActive = true})
        
        addSubview(openCloseButton)
        [openCloseButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
         openCloseButton.leadingAnchor.constraint(equalTo: headerTitleLabel.trailingAnchor, constant: 8),
         openCloseButton.centerYAnchor.constraint(equalTo: centerYAnchor),
         openCloseButton.heightAnchor.constraint(equalTo: heightAnchor)].forEach({$0.isActive = true})
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
