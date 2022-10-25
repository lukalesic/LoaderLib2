//
//  MoreInfoTableViewCell.swift
//  MarvelLoader
//
//  Created by Luka Lešić on 12.10.2022..
//

import UIKit

class IssueNumberTableViewCell: UITableViewCell {
    
    var IssueNumberViewModel = IssueNumberCellViewModel()
    
    var issueNumber: UILabel = {
            let label = UILabel()
            label.numberOfLines = 0
            label.font = label.font.withSize(15)
            label.text = ""
            return label
        }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear
        self.backgroundColor = .clear
        displayLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func displayLayout(){
        contentView.addSubview(issueNumber)
        setIssueNumberConstraints()
    }
    
    func setIssueNumberConstraints(){
       issueNumber.configureForAutoLayout()
       issueNumber.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.init(top: 8, left: 10, bottom: 8, right: 10))
   }

    func setComicDetails(comic: Comic){
        if comic.issueNumber == 0 {issueNumber.text = "No issue number available"}
        else {  issueNumber.text = "Issue number: \(comic.issueNumber!)"
        }
        
    }
}