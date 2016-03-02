//
//  SearchViewController.swift
//  Book Antenna
//
//  Created by Zeyuan Xu on 2/25/16.
//  Copyright © 2016 Heraclitus.corp. All rights reserved.
//

import UIKit
import MediaPlayer

class SearchViewController: UIViewController {
    var activeDownloads = [String: Download]()
    
    // set up a default NSURLSession
    let defaultSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    // set up a datatask for managing download process
    var dataTask: NSURLSessionDataTask?
    
    let db  = Database()

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var searchResults = [Track]()
    
    lazy var tapRecognizer: UITapGestureRecognizer = {
        var recognizer = UITapGestureRecognizer(target:self, action: "dismissKeyboard")
        return recognizer
    }()
    
    lazy var downloadsSession: NSURLSession = {
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("bgSessionConfiguration")
        let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()
    
    // MARK: View controller methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        _ = self.downloadsSession
        
        let documentDirectoryURL =  try! NSFileManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        NSLog("%@", documentDirectoryURL)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Handling Search Results
    
    // This helper method helps parse response JSON NSData into an array of Track objects.
    func updateSearchResults(data: NSData?) {
        searchResults.removeAll()
        do {
            if let data = data, response = try NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions(rawValue:0)) as? [String: AnyObject] {
                
                //responseCount is zero
                if (response["resultCount"] as! Int == 0)
                {
                    print("No result found")
                }
                // Get the results array
                if let array: AnyObject = response["results"] {

                    for trackDictonary in array as! [AnyObject] {
                        if let trackDictonary = trackDictonary as? [String: AnyObject], previewUrl = trackDictonary["previewUrl"] as? String {
                            // Parse the search result
                            let name = trackDictonary["collectionName"] as? String
                            let artist = trackDictonary["artistName"] as? String
                            searchResults.append(Track(name: name, artist: artist, previewUrl: previewUrl))
                        } else {
                            print("Not a dictionary")
                        }
                    }
                } else {
                    print("Results key not found in dictionary")
                }
            } else {
                print("JSON Error")
            }
        } catch let error as NSError {
            print("Error parsing results: \(error.localizedDescription)")
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
            self.tableView.setContentOffset(CGPointZero, animated: false)
        }
    }
    
    // MARK: Keyboard dismissal
    
    func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }
    
    // MARK: Download methods
    
    // Called when the Download button for a track is tapped
    func startDownload(track: Track) {
        if let urlString = track.previewUrl, url =  NSURL(string: urlString) {
            // initiate the Download object
            let download = Download(url: urlString)
            // create a DownloadTask with the preview URL, set it to the downloadTask
            download.downloadTask = downloadsSession.downloadTaskWithURL(url)
            // start the downloading task by calling resume
            download.downloadTask!.resume()
            // indicate downloading in progress
            download.isDownloading = true
            // Map the download url to the active download dcitionary
            activeDownloads[download.url] = download
            
        }
    }
    
    // Called when the Pause button for a track is tapped
    func pauseDownload(track: Track) {
        if let urlString = track.previewUrl,
            download = activeDownloads[urlString] {
                if(download.isDownloading) {
                    download.downloadTask?.cancelByProducingResumeData { data in
                        if data != nil {
                            download.resumeData = data
                        }
                    }
                    download.isDownloading = false
                }
        }
    }
    
    // Called when the Cancel button for a track is tapped
    func cancelDownload(track: Track) {
        if let urlString = track.previewUrl,
            download = activeDownloads[urlString] {
                download.downloadTask?.cancel()
                activeDownloads[urlString] = nil
        }
    }
    
    // Called when the Resume button for a track is tapped
    func resumeDownload(track: Track) {
        if let urlString = track.previewUrl,
            download = activeDownloads[urlString] {
                if let resumeData = download.resumeData {
                    download.downloadTask = downloadsSession.downloadTaskWithResumeData(resumeData)
                    download.downloadTask!.resume()
                    download.isDownloading = true
                } else if let url = NSURL(string: download.url) {
                    download.downloadTask = downloadsSession.downloadTaskWithURL(url)
                    download.downloadTask!.resume()
                    download.isDownloading = true
                }
        }
    }
    
    // This method attempts to play the local file (if it exists) when the cell is tapped
    func playDownload(track: Track) {
        if let urlString = track.previewUrl, url = localFilePathForUrl(track, previewUrl: urlString) {
            let moviePlayer:MPMoviePlayerViewController! = MPMoviePlayerViewController(contentURL: url)
            presentMoviePlayerViewControllerAnimated(moviePlayer)
        }
    }
    
    // MARK: Download helper methods
    
    // This method generates a permanent local file path to save a track to by appending
    // the lastPathComponent of the URL (i.e. the file name and extension of the file)
    // to the path of the app’s Documents directory.
    func localFilePathForUrl(track: Track, previewUrl: String) -> NSURL? {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        if let url = NSURL(string: previewUrl), lastPathComponent = url.lastPathComponent {
            let fullPath = documentsPath.stringByAppendingPathComponent(lastPathComponent)
            return NSURL(fileURLWithPath:fullPath)
        }
        return nil
    }
    
 
    

    // This method checks if the local file exists at the path generated by localFilePathForUrl(_:)
    func localFileExistsForTrack(track: Track) -> Bool {
        if let urlString = track.previewUrl, localUrl = localFilePathForUrl(track, previewUrl: urlString) {
            var isDir : ObjCBool = false
            if let path = localUrl.path {
                return NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDir)
            }
        }
        return false
    }
    
    func trackIndexForDownloadTask(downloadTask: NSURLSessionDownloadTask) -> Int? {
        if let url = downloadTask.originalRequest?.URL?.absoluteString {
            for (index, track) in searchResults.enumerate() {
                if url == track.previewUrl! {
                    return index
                }
            }
        }
        return nil
    }
    
    
}

// MARK: - NSURLSessionDelegate

extension SearchViewController: NSURLSessionDelegate {
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            if let completionHandler = appDelegate.backgroundSessionCompletionHandler {
                appDelegate.backgroundSessionCompletionHandler = nil
                dispatch_async(dispatch_get_main_queue(), {
                    completionHandler()
                })
            }
        }
    }
}


//MARK : 

// MARK: - NSURLSessionDownloadDelegate

extension SearchViewController: NSURLSessionDownloadDelegate {
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        // extract the original request URL and use it to find local path
        let track = searchResults[trackIndexForDownloadTask(downloadTask)!]
        if let originalURL = downloadTask.originalRequest?.URL?.absoluteString,
            destinationURL = localFilePathForUrl(track, previewUrl: originalURL) {
                
                print(destinationURL)
                
                let fileName = NSURL(string : track.previewUrl!)!.lastPathComponent
                var songName = track.name!
                if(songName.containsString("'")){
                    songName = songName.stringByReplacingOccurrencesOfString("\'", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)

                }
                
                //Insert song into database
                let insert = "insert into audio (song_name, author_name, file_name) values ('\(songName)','\(track.artist!)','\(fileName!)')"
                NSLog("%@" ,insert)
                db.Insert(insert)

                //move the downloaded files from its temporary file location to the destination directory
                let fileManager = NSFileManager.defaultManager()
                do {
                    try fileManager.removeItemAtURL(destinationURL)
                } catch {
                    // Non-fatal: file probably doesn't exist
                }
                do {
                    try fileManager.copyItemAtURL(location, toURL: destinationURL)
                } catch let error as NSError {
                    print("Could not copy file to disk: \(error.localizedDescription)")
                }
        }
        
        //after the download, remove the corresponding item in activeDownloads
        if let url = downloadTask.originalRequest?.URL?.absoluteString {
            activeDownloads[url] = nil
            //reload the corresponding TrackCell.
            if let trackIndex = trackIndexForDownloadTask(downloadTask) {
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: trackIndex, inSection: 0)], withRowAnimation: .None)
                })
            }
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        // use downloadTask to extract URL and find the downloaded file in activeDownloads
        if let downloadUrl = downloadTask.originalRequest?.URL?.absoluteString,
            download = activeDownloads[downloadUrl] {
                //the downloading progress is the ratio between total bytes and downloaded bytes
                download.progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
                //generate a human readable string that shows the total download file size.
                let totalSize = NSByteCountFormatter.stringFromByteCount(totalBytesExpectedToWrite, countStyle: NSByteCountFormatterCountStyle.Binary)
                // update the TrackCell by updating the progress view and progress label
                if let trackIndex = trackIndexForDownloadTask(downloadTask), let trackCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: trackIndex, inSection: 0)) as? TrackCell {
                    dispatch_async(dispatch_get_main_queue(), {
                        trackCell.progressView.progress = download.progress
                        trackCell.progressLabel.text =  String(format: "%.1f%% of %@",  download.progress * 100, totalSize)
                    })
                }
        }
    }
}

// MARK: - UISearchBarDelegate

extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        dismissKeyboard()
        
        if !searchBar.text!.isEmpty {
            //after the user query, check if the task is already initialized, if so, cancel the task
            if dataTask != nil {
                dataTask?.cancel()
            }
            //enable network activity bar to show that network process is going on
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            //check if the user input is a valid and properly escaped.
            let expectedCharSet = NSCharacterSet.URLQueryAllowedCharacterSet()
            let searchTerm = searchBar.text!.stringByAddingPercentEncodingWithAllowedCharacters(expectedCharSet)!
            //create a NSURL, and the search variable is used as GET parameter to iTunes Search API
            let url = NSURL(string: "https://itunes.apple.com/search?media=audiobook&entity=audiobook&term=\(searchTerm)")
            //use a dataTaskWithURL to handle the HTTP GET request
            dataTask = defaultSession.dataTaskWithURL(url!) {
                data, response, error in
                //update the table view in main thread
                dispatch_async(dispatch_get_main_queue()) {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
                //check error, and if no error, update the search results dictionary
                if let error = error {
                    print(error.localizedDescription)
                } else if let httpResponse = response as? NSHTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        self.updateSearchResults(data)
                    }
                }
            }
            //all tasks start in a suspended state by default, call resume() starts the data task.
            dataTask?.resume()
        }
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        view.addGestureRecognizer(tapRecognizer)
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        view.removeGestureRecognizer(tapRecognizer)
    }
}

// MARK: TrackCellDelegate

extension SearchViewController: TrackCellDelegate {
    func pauseTapped(cell: TrackCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
            let track = searchResults[indexPath.row]
            pauseDownload(track)
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
        }
    }
    
    func resumeTapped(cell: TrackCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
            let track = searchResults[indexPath.row]
            resumeDownload(track)
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
        }
    }
    
    func cancelTapped(cell: TrackCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
            let track = searchResults[indexPath.row]
            cancelDownload(track)
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
        }
    }
    
    func downloadTapped(cell: TrackCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
            let track = searchResults[indexPath.row]
            startDownload(track)
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
        }
    }
}

// MARK: UITableViewDataSource

extension SearchViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TrackCell", forIndexPath: indexPath) as!TrackCell
        
        // Delegate cell button tap events to this view controller
        cell.delegate = self
        
        let track = searchResults[indexPath.row]
        
        // Configure title and artist labels
        cell.titleLabel.text = track.name
        cell.artistLabel.text = track.artist
        
        var showDownloadControls = false
        if let download = activeDownloads[track.previewUrl!] {
            showDownloadControls = true
            
            cell.progressView.progress = download.progress
            cell.progressLabel.text = (download.isDownloading) ? "Downloading..." : "Paused"
            
            let title = (download.isDownloading) ? "Pause" : "Resume"
            cell.pauseButton.setTitle(title, forState: UIControlState.Normal)
        }
        cell.progressView.hidden = !showDownloadControls
        cell.progressLabel.hidden = !showDownloadControls
        
        // If the track is already downloaded, enable cell selection and hide the Download button
        let downloaded = localFileExistsForTrack(track)
        cell.selectionStyle = downloaded ? UITableViewCellSelectionStyle.Gray : UITableViewCellSelectionStyle.None
        cell.downloadButton.hidden = downloaded || showDownloadControls
        
        cell.pauseButton.hidden = !showDownloadControls
        cell.cancelButton.hidden = !showDownloadControls
        
        return cell
    }
}

// MARK: UITableViewDelegate

extension SearchViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 62.0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let track = searchResults[indexPath.row]
        if localFileExistsForTrack(track) {
            playDownload(track)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

