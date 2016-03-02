//
//  BookViewController.swift
//  Book Antenna
//
//  Created by Zeyuan Xu on 3/1/16.
//  Copyright © 2016 Heraclitus.corp. All rights reserved.
//

import UIKit
import MediaPlayer


class BookViewController: UITableViewController {

    //Database object
    let db  = Database()
    
    //Array of all the downloaded audio
    var arrAudio = NSMutableArray()
    
    //Outlet of table
    @IBOutlet var tblBookShelf: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Select all audio from database
        self.selectAllAudio()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    override func viewWillAppear(animated: Bool) {
        
        //Select all audio list from database
        self.selectAllAudio()
        NSLog("%@", arrAudio)
        self.tblBookShelf.reloadData()
    }
    
    // Function to select all the audio files downloaded
    func selectAllAudio(){
        let select = "select * from audio"
        NSLog("%@", select)
        arrAudio = db.SelectAllFromTable(select)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return arrAudio.count
    }

   
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("BookCell", forIndexPath: indexPath)

        cell.textLabel?.text = arrAudio.objectAtIndex(indexPath.row).valueForKey("song_name") as! String
        cell.detailTextLabel?.text = arrAudio.objectAtIndex(indexPath.row).valueForKey("author_name") as! String
        return cell
    }
    
    //click to play the audiobook
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let audiofileURL = self.arrAudio.objectAtIndex(indexPath.row).valueForKey("file_name") as! String
        playBook(audiofileURL)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    
    //play the audio book file
    func playBook (fileURL : String){
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        if paths.count > 0 {
            let dirPath = paths[0]
            let filePath = NSString(format:"%@/%@", dirPath, fileURL) as? String
            let filePathURL = NSURL.fileURLWithPath(filePath!)
            print(filePathURL)
            let moviePlayer:MPMoviePlayerViewController! = MPMoviePlayerViewController(contentURL: filePathURL)
            if NSFileManager.defaultManager().fileExistsAtPath(filePath!) {
                do {
                    presentMoviePlayerViewControllerAnimated(moviePlayer)
                } catch {
                    print("local file doesn't exist")
                }

        }
      }
    }
    
    
    /*====TABLE VIEW SWIPE OPTIONS====*/
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: (UITableView!), commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: (NSIndexPath!)) {
        
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        //Actionsheet for delete confirmation
        let deleteAction = UITableViewRowAction(style: .Normal, title: " DELETE ") {action in
            let deleteMenu = UIAlertController(title: nil, message: "Sure to delete?", preferredStyle: UIAlertControllerStyle.ActionSheet)
            let delete = UIAlertAction(title: "Delete", style: UIAlertActionStyle.Default, handler: { (UIAlertAction)in
                
                //select object from array to delete
                let fileName = self.arrAudio.objectAtIndex(indexPath.row).valueForKey("file_name") as! String
                
                //delete file from document directory
                self.deleteFileFromDocumentDirectory(fileName)
                
                //delete files from database
                let delete = "DELETE from audio WHERE file_name = '\(fileName)'"
                NSLog("%@", delete)
                self.db.Delete(delete)
                
                self.selectAllAudio()
                
                // Realod table
                self.tblBookShelf.reloadData()
                NSLog("Delete %d",indexPath.row)
                
            })
            let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
            deleteMenu.addAction(delete)
            deleteMenu.addAction(cancel)
            self.presentViewController(deleteMenu, animated: true, completion: nil)
            
        }
        deleteAction.backgroundColor = UIColor.redColor()
        
        return [deleteAction]
    }
    
    // Function to delete file from document directory
    func deleteFileFromDocumentDirectory(fileURL : String){
            let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            if paths.count > 0 {
                let dirPath = paths[0]
                let filePath = NSString(format:"%@/%@", dirPath, fileURL) as String
                if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
                    do {
                        try NSFileManager.defaultManager().removeItemAtPath(filePath)
                        print("old song has been removed")
                        
                    } catch {
                        print("an error during a removing")
                    }
                }
            }
        }
    
    
    
    
    
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}








