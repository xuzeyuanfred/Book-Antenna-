//
//  BookCell.swift
//  Book Antenna
//
//  Created by Siliangyu Cheng on 2/29/16.
//  Copyright © 2016 Heraclitus.corp. All rights reserved.
//

import UIKit

protocol BookCellDelegate {
    func deleteTapped(cell: BookCell)
}


class BookCell: UITableViewCell {
    
    var bookdelegate : BookCellDelegate?
    
    @IBOutlet weak var authorLabel : UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBAction func deleteTapped (sender: AnyObject) {
        bookdelegate?.deleteTapped(self)
    }
}