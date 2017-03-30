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

class PlaceController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout  {
    
    var place: (String, String)?
    var placeImage: UIImage?
    var posts = [Post]()
    
    let refreshControl = UIRefreshControl()
    
    @IBOutlet weak var postsCollectionView: UICollectionView!

    override func viewDidLoad() {
        
        self.view.backgroundColor = UIColor.blue.dark
        
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

    //MARK: - Collection View Delegate & DataSource
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PostCell
        
        if !self.refreshControl.isRefreshing{
            
            let post = posts[(indexPath as NSIndexPath).row]
            
            if let mediaUrl = post.mediaUrl {
                cell.postImageView.af_setImage(withURL: URL(string: mediaUrl)!, filter: AspectScaledToFillSizeFilter(size: cell.postImageView.frame.size), imageTransition: .crossDissolve(0.1))
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader{
            
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView", for: indexPath) as! PostHeaderReusableView
           
            headerView.headerImageView.image = placeImage
            
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
    
}
