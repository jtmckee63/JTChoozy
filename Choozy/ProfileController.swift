//
//  ProfileController.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/29/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import UIKit
import Parse
import SwiftyDrop
import AlamofireImage
import AVKit
import AVFoundation

class ProfileController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout  {
    
    var posts = [Post]()
    
    let refreshControl = UIRefreshControl()
    @IBOutlet var profileCollectionView: UICollectionView!
    
    var user: ChoozyUser?
    
    var likes = Int()
    var views = Int()
    
    let blurple = UIColor(red:0.25, green:0.00, blue:1.00, alpha:1.0)
    let lightGreen = UIColor(red:0.05, green:1.00, blue:0.00, alpha:1.0)
    let black: UIColor = UIColor.black
    let darkGray = UIColor(red:0.25, green:0.25, blue:0.25, alpha:1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.view.backgroundColor = UIColor.blue.light
        self.view.backgroundColor = darkGray

        //Title
        setTitle()
        
        //Profile Collection View
        profileCollectionView.delegate = self
        profileCollectionView.dataSource = self
        profileCollectionView.register(UINib(nibName: "UserPostCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        profileCollectionView.backgroundColor = UIColor.clear
        profileCollectionView.register(UINib(nibName: "ProfileHeaderReusableView", bundle: nil), forSupplementaryViewOfKind:UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView")
        profileCollectionView.indicatorStyle = .white
        profileCollectionView.alwaysBounceVertical = true
        
        //Refresh Control for our Collection View
        refreshControl.tintColor = UIColor.white.pure
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh", attributes: [NSForegroundColorAttributeName: UIColor.white.pure.withAlphaComponent(0.7), NSFontAttributeName: UIFont.init(name: "Avenir-Heavy", size: 8.0)!])
        refreshControl.addTarget(self, action: #selector(refreshAllData), for: .valueChanged)
        profileCollectionView.addSubview(refreshControl)
        
        //Initial Call to load our data.
        refreshAllData()

    }
    
    //MARK: - Core Functions
    func pullToRefresh(){
        refreshAllData()
    }
    
    func refreshAllData(){
        
        posts.removeAll()
        likes = 0
        views = 0
        
        loadPosts()
    }
    
    func loadPosts(){
        
        guard let authorId = user?.objectId else{
            return
        }
    
        let postsQuery = PFQuery(className: "Post")
        postsQuery.limit = 1000
        postsQuery.includeKeys(["author"])
        postsQuery.whereKey("authorId", equalTo: authorId)
        postsQuery.order(byDescending: "createdAt")
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
                        
                        self.likes += likes
                        self.views += views
                        
                        DispatchQueue.main.async(execute: {
                            self.profileCollectionView.reloadData()
                        })
                    }
                }
            }
            
            if self.refreshControl.isRefreshing{
                self.refreshControl.endRefreshing()
            }
        })
    }
    
    func setTitle(){
        
        guard let firstName = user?.firstName, let lastName = user?.lastName else {
            return
        }
        
        
        title = "\(firstName) \(lastName)"
    }
    
    //MARK: - Collection View Delegate & DataSource
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! UserPostCell
        
        if !self.refreshControl.isRefreshing{
            
            let post = posts[(indexPath as NSIndexPath).row]
            
            if let mediaUrl = post.mediaUrl, let placeName = post.placeName {
                
                if mediaUrl.contains(".mov") {
                    let videoURL = Foundation.URL(string: mediaUrl)
                    
                    let videoImage = thumbnailForVideoAtURL(url: videoURL!)
                    cell.postImageView.image = videoImage
                    cell.postDetailLabel.text = placeName

                    
                } else {
                    cell.postImageView.af_setImage(withURL: URL(string: mediaUrl)!, filter: AspectScaledToFillSizeFilter(size: cell.postImageView.frame.size), imageTransition: .crossDissolve(0.1))
                    cell.postDetailLabel.text = placeName
                }
//                cell.postImageView.af_setImage(withURL: URL(string: mediaUrl)!, filter: AspectScaledToFillSizeFilter(size: cell.postImageView.frame.size), imageTransition: .crossDissolve(0.1))
//                cell.postDetailLabel.text = placeName
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader{
            
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView", for: indexPath) as! ProfileHeaderReusableView
            
            if let profileImageUrl = user?.profilePictureUrl {
                
                headerView.profileImageView.af_setImage(withURL: URL(string: profileImageUrl)!, placeholderImage: UIImage(named: "person"), filter: AspectScaledToFillSizeCircleFilter(size: headerView.profileImageView.frame.size), imageTransition: .crossDissolve(0.1))
                
                headerView.viewsLabel.text = "\(views)"
                headerView.postsLabel.text = "\(posts.count)"
                headerView.likesLabel.text  = "\(likes)"
            }
            let postCount = self.posts.count
            if postCount > 1 {
                headerView.badge.image = UIImage(named: "badge1")
                headerView.badge.layer.masksToBounds = false
                headerView.badge.layer.borderColor = UIColor.black.cgColor
                headerView.badge.clipsToBounds = true
                
            }
            if postCount > 25 {
                headerView.badge.image = UIImage(named: "badge2")
                headerView.badge.layer.masksToBounds = false
                headerView.badge.layer.borderColor = UIColor.black.cgColor
                headerView.badge.clipsToBounds = true
            }
            if postCount > 50 {
                headerView.badge.image = UIImage(named: "badge3")
                headerView.badge.layer.masksToBounds = false
                headerView.badge.layer.borderColor = UIColor.black.cgColor
                headerView.badge.clipsToBounds = true
            }
            if postCount > 75 {
                headerView.badge.image = UIImage(named: "badge4")
                headerView.badge.layer.masksToBounds = false
                headerView.badge.layer.borderColor = UIColor.black.cgColor
                headerView.badge.clipsToBounds = true
            }
            if postCount > 100 {
                headerView.badge.image = UIImage(named: "badge5")
                headerView.badge.layer.masksToBounds = false
                headerView.badge.layer.borderColor = UIColor.black.cgColor
                headerView.badge.clipsToBounds = true
            }
            return headerView
            
        }else{
            return UICollectionReusableView() as! ProfileHeaderReusableView
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: profileCollectionView.bounds.size.width, height: ProfileHeaderReusableView.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let post = posts[(indexPath as NSIndexPath).row]
        self.showDetailController(post)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    //Size of the Cell
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.bounds.width / 3 - 1, height: UserPostCell.height)
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
        let asset = AVAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        let imgGen = AVAssetImageGenerator(asset:asset)

        imgGen.appliesPreferredTrackTransform = true
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
