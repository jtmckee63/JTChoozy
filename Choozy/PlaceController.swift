//
//  PlaceController.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/29/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import UIKit
import Parse
import SwiftyDrop
import AlamofireImage
import GooglePlaces
import AVKit
import AVFoundation

class PlaceController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout  {
    
    var place: (String, String)?
    var placeImage: UIImage?
    var posts = [Post]()
    
    
    let refreshControl = UIRefreshControl()
    let headerView = PostHeaderReusableView()
    
    @IBOutlet weak var postsCollectionView: UICollectionView!

    //colors JT
    var lightBlue = UIColor(red:0.42, green:0.93, blue:1.00, alpha:1.0)
    var blurple = UIColor(red:0.25, green:0.00, blue:1.00, alpha:1.0)
    var lightGreen = UIColor(red:0.05, green:1.00, blue:0.00, alpha:1.0)
    var black: UIColor = UIColor.black
    let darkGray = UIColor(red:0.25, green:0.25, blue:0.25, alpha:1.0)

    override func viewDidLoad() {
        
//        self.view.backgroundColor = UIColor.blue.dark
        self.view.backgroundColor = darkGray
        
        //Title
        setTitle()
        
        //Posts Collection View
        postsCollectionView.delegate = self
        postsCollectionView.dataSource = self
        postsCollectionView.register(UINib(nibName: "PostCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        postsCollectionView.backgroundColor = UIColor.clear
        postsCollectionView.register(UINib(nibName: "PostHeaderReusableView", bundle: nil), forSupplementaryViewOfKind:UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView")
        postsCollectionView.indicatorStyle = .white
        postsCollectionView.alwaysBounceVertical = true
        
        //Refresh Control for our Collection View
        refreshControl.tintColor = UIColor.white.pure
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh", attributes: [NSForegroundColorAttributeName: UIColor.white.pure.withAlphaComponent(0.7), NSFontAttributeName: UIFont.init(name: "Avenir-Heavy", size: 8.0)!])
        refreshControl.addTarget(self, action: #selector(refreshAllData), for: .valueChanged)
        postsCollectionView.addSubview(refreshControl)
        
        //Initial Call to load our data.
        refreshAllData()
    }
    
    //MARK: - Core Functions
    func pullToRefresh(){
        refreshAllData()
    }
    
    func refreshAllData(){
        posts.removeAll()
        loadPosts()
    }
    func goToPostController(){
        if isUserLoggedIn(){
            placePost = false
            self.showPostController()
        }
    }
    func goToPostForPlace(){
        if isUserLoggedIn() {
            print((place?.0)!,(place?.1)!)
            placePost = true
            print(placePost)
            self.exPlacePoster((place?.0)!, placeName: (place?.1)!)
        }
    }
    func loadPosts(){
        if let placeId = place?.0 {
            
            if placeImage == nil{
                loadPhotoForPlace(with: placeId)
            }
            
            let postsQuery = PFQuery(className: "Post")
            postsQuery.includeKeys(["author"])
            postsQuery.whereKey("placeId", equalTo: placeId)
            postsQuery.limit = 1000
            postsQuery.findObjectsInBackground(block: {(objects: [PFObject]?, error: Error?) -> Void in
                if let error = error{
                    print(error)
                    Drop.down(" There was an error finding posts. Please try again.", state: Custom.error)
                }else{
                    if !(objects?.isEmpty)!{
                        
                        for object in objects!{
                            
                            guard
                                let id = object.objectId,
                                let likes = object["likes"] as? Int,
                                let views = object["views"] as? Int,
                                let subAddress = object["subAddress"] as? String,
                                let address = object["address"] as? String,
                                let city = object["city"] as? String,
                                let state = object["state"] as? String,
                                let country = object["country"] as? String,
                                let location = object["location"] as? PFGeoPoint,
                                let author = object["author"] as? ChoozyUser,
                                let authorId = object["authorId"] as? String,
                                let mediaUrl = object["mediaUrl"] as? String,
                                let placeId = object["placeId"] as? String,
                                let placeName = object["placeName"] as? String,
                                let timeStamp = object.createdAt,
                                let updatedTimeStamp = object.updatedAt
                            else{
                                continue
                            }
                            
                            let post = Post()
                            post.objectId = id
                            post.id = id
                            post.likes = likes
                            post.views = views
                            post.subAddress = subAddress
                            post.address = address
                            post.city = city
                            post.state = state
                            post.country = country
                            post.location = location
                            post.author = author
                            post.authorId = authorId
                            post.mediaUrl = mediaUrl
                            post.placeId = placeId
                            post.placeName = placeName
                            post.timeStamp = timeStamp
                            post.updatedTimeStamp = updatedTimeStamp
                            
                            self.posts.append(post)
                            
                            DispatchQueue.main.async(execute: {
                                self.postsCollectionView.reloadData()
                            })
                        }
                    }
                }
                
                if self.refreshControl.isRefreshing{
                    self.refreshControl.endRefreshing()
                }
            })
        }
    }
    
    func setTitle(){
        
        guard let placeName = place?.1 else{
            return
        }
        
        title = placeName
    }
    
    func loadPhotoForPlace(with id: String){
        GMSPlacesClient.shared().lookUpPhotos(forPlaceID: id) { (photos, error) -> Void in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else {
                if let firstPhoto = photos?.results.first {
                    GMSPlacesClient.shared().loadPlacePhoto(firstPhoto, callback: { (photo, error) -> Void in
                        if let error = error {
                            print("Error: \(error.localizedDescription)")
                        } else {
                            
                            self.placeImage = photo!
                            DispatchQueue.main.async(execute: {
                                self.postsCollectionView.reloadData()
                            })
                            
                        }
                    })
                }
            }
        }
    }
    //JT added for new post button
    
    //MARK: - Collection View Delegate & DataSource
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PostCell
        
        if !self.refreshControl.isRefreshing{
            
            let post = posts[(indexPath as NSIndexPath).row]
            
            if let mediaUrl = post.mediaUrl {
                if mediaUrl.contains(".mov") {
                    let videoURL = Foundation.URL(string: mediaUrl)
                    
                    let videoImage = thumbnailForVideoAtURL(url: videoURL!)
                    cell.postImageView.image = videoImage
                    
                } else {
                    
                    cell.postImageView.af_setImage(withURL: URL(string: mediaUrl)!, filter: AspectScaledToFillSizeFilter(size: cell.postImageView.frame.size), imageTransition: .crossDissolve(0.1))
                }
            }
            
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader{
            
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView", for: indexPath) as! PostHeaderReusableView
           
            headerView.headerImageView.image = placeImage
            headerView.postButton.addTarget(self, action: #selector(goToPostForPlace), for: .touchUpInside)
            let postB = headerView.postButton
            postB?.layer.cornerRadius = 0.5 * (postB?.bounds.size.width)!
            postB?.clipsToBounds = true
            return headerView
            
        }else{
            return UICollectionReusableView() as! PostHeaderReusableView
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: postsCollectionView.bounds.size.width, height: 395)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let post = posts[(indexPath as NSIndexPath).row]
        self.showDetailController(post)
        
        print("inside collectionView did select")
    
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    //Size of the Cell
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.bounds.width / 3 - 1, height: view.bounds.width / 3 - 1)
    }
    
    //Line Spacing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    //MARK: - Prepare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detail" {
            let detailController: DetailController = segue.destination as! DetailController
            detailController.post = (sender as? Post)!
            
            let backItem = UIBarButtonItem()
            backItem.title = ""
            navigationItem.backBarButtonItem = backItem
        }
    }
    
    //MARK: - Status Bar
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    //JT added for thumbnails
    private func thumbnailForVideoAtURL(url: URL) -> UIImage? {
//        let asset = AVAsset(url: url)
//        let imgGen = AVAssetImageGenerator(asset:asset)
//        imgGen.appliesPreferredTrackTransform = true
//        var time = asset.duration
//        time.value = min(time.value, 1)
//        print(time)
//    
//        do {
//            print(time)
//            let imageRef = try imgGen.copyCGImage(at: time, actualTime: nil)
//            
//            return UIImage(cgImage: imageRef)
//            
//        } catch {
//            print("Error with thumbnails")
//            return nil
//        }
        let asset = AVAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        let imgGen = AVAssetImageGenerator(asset:asset)
        
        imgGen.appliesPreferredTrackTransform = true
        //        var time = asset.duration
        //        time.value = min(time.value, 2)
        let time = CMTimeMakeWithSeconds(duration/3.0, 600)
        var img: CGImage
        
        do {
            img = try imgGen.copyCGImage(at: time, actualTime: nil)
            let frameImg: UIImage = UIImage(cgImage: img)
            
            return frameImg
        } catch let error as NSError {
            print("ERROR ON THUMBNAIL: \(error)")
            return UIImage(named:"cameraIcon")
        }
        
    }

    
}
