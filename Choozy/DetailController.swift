//
//  DetailController.swift
//  Choozy
//
//  Created by Cameron Eubank on 3/29/17.
//  Copyright © 2017 Cameron Eubank. All rights reserved.
//

import UIKit
import CoreData
import Parse
import Alamofire
import AlamofireImage
import SwiftyDrop
import SCLAlertView
import MediaPlayer


class DetailController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var detailTableView: UITableView!
    //colors JT
    var lightBlue = UIColor(red:0.42, green:0.93, blue:1.00, alpha:1.0)
    var blurple = UIColor(red:0.25, green:0.00, blue:1.00, alpha:1.0)
    var lightGreen = UIColor(red:0.05, green:1.00, blue:0.00, alpha:1.0)
    var black: UIColor = UIColor.black
    let darkGray = UIColor(red:0.25, green:0.25, blue:0.25, alpha:1.0)

    
    //JT added for video
    @IBOutlet var mediaView: UIView!
    var moviePlayerController = MPMoviePlayerController()
    var defaultCameraImage = UIImage(named: "cameraImage")
    var selectedMovieURL: URL?
    var selectedImageFromPicker: UIImage?
//    var player:AVPlayer?
    var player = AVPlayer()
    var playerLayer = AVPlayerLayer()
    var playerItem:AVPlayerItem?
    
    let refreshControl = UIRefreshControl()
    
    //Variables
    var post = Post()
    var comments: [Comment] = []
    
    //JT disable like
    var canLike = true

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Bar Button Items
        let moreButton = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        moreButton.contentMode = .scaleAspectFill
        moreButton.setImage(UIImage(named: "moreIcon"), for: .normal)
        moreButton.addTarget(self, action: #selector(showMoreOptionsAlertController), for: .touchUpInside)
        let moreBarButtonItem = UIBarButtonItem(customView: moreButton)
        
        let shareButton = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        shareButton.contentMode = .scaleAspectFill
        shareButton.setImage(UIImage(named: "shareIcon"), for: .normal)
        shareButton.addTarget(self, action: #selector(sharePost), for: .touchUpInside)
        let shareBarButtonItem = UIBarButtonItem(customView: shareButton)
        
        self.navigationItem.setRightBarButtonItems([moreBarButtonItem, shareBarButtonItem], animated: false)
//        self.view.backgroundColor = UIColor.blue.light
        self.view.backgroundColor = darkGray
        
        //Detail Table View
        detailTableView.delegate = self
        detailTableView.dataSource = self
        detailTableView.register(UINib(nibName: "DetailHeaderCell", bundle: nil), forCellReuseIdentifier: "headerCell")
        detailTableView.register(UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: "commentCell")
//        detailTableView.backgroundColor = UIColor.blue.light
        detailTableView.backgroundColor = black
        detailTableView.separatorStyle = .none
        detailTableView.indicatorStyle = .white
        detailTableView.estimatedRowHeight = 70
        detailTableView.alwaysBounceVertical = true
        
        //Refresh Control for our Table View
        refreshControl.tintColor = UIColor.white.pure
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh : )", attributes: [NSForegroundColorAttributeName: UIColor.white.pure.withAlphaComponent(0.7), NSFontAttributeName: UIFont.init(name: "Avenir-Heavy", size: 8.0)!])
        refreshControl.addTarget(self, action: #selector(refreshAllDataFromRefresh), for: .valueChanged)
        detailTableView.addSubview(refreshControl)
        
        refreshAllData()
        
        //Increase the view count
        increaseViewCount(post: post, amount: 1)
    }
    
    //MARK: - Core Methods
    func refreshAllData(){
        
        comments.removeAll()
        
        setupTitle(post: post)
        loadComments(post: post)
    }
    
    func loadComments(post: Post){
        
        guard let postId = post.id else{
            return
        }
        
        let commentsQuery = PFQuery(className: "Comment")
        commentsQuery.limit = 1000
        commentsQuery.includeKeys(["author"])
        commentsQuery.whereKey("postId", equalTo: postId)
        commentsQuery.order(byAscending: "createdAt")
        commentsQuery.findObjectsInBackground(block: {(objects: [PFObject]?, error: Error?) -> Void in
            if let error = error{
                print(error)
                Drop.down(" : ( There was an error finding comments for this post. Please try again.", state: Custom.error)
            }else{
                if !(objects?.isEmpty)!{
                    
                    for object in objects!{
                        
                        guard
                            let id = object.objectId,
                            let content = object["comment"] as? String,
                            let author = object["author"] as? ChoozyUser,
                            let timeStamp = object.createdAt,
                            let updatedTimeStamp = object.updatedAt
                            else{
                                continue
                        }
                        
                        let comment = Comment()
                        comment.objectId = id
                        comment.id = id
                        comment.comment = content
                        comment.author = author
                        comment.timeStamp = timeStamp
                        comment.updatedTimeStamp = updatedTimeStamp
                        
                        self.comments.append(comment)
                        
                        DispatchQueue.main.async(execute: {
                            self.detailTableView.reloadData()
                        })
                    }
                }
            }
            
            if self.refreshControl.isRefreshing{
                self.refreshControl.endRefreshing()
            }
        })
    }
    
    func setupTitle(post: Post){

        guard let date = post.timeStamp else{
            return
        }
        
        title = getDateStringFromDate(date)
    }
    
    var avPlayerAdded = false
    //MARK: - UITableView Delegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = indexPath.section
        
        switch section{
        case 0:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell") as! DetailHeaderCell
            
            if !self.refreshControl.isRefreshing{
                
                if let mediaUrl = post.mediaUrl{
                    
                    //JT added
                    if mediaUrl.contains(".mov")
                    {
                        if !avPlayerAdded{
                            
                            cell.mediaView.contentMode = .scaleAspectFit
                            
                            let videoURL = Foundation.URL(string: mediaUrl)
                            self.player = AVPlayer(url: videoURL!)
                            self.playerLayer = AVPlayerLayer(player: player)
                            
                            playerLayer.masksToBounds = true
                            player.allowsExternalPlayback = true
                            playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                            
                            cell.mediaView.layer.addSublayer(playerLayer)
                            playerLayer.frame = cell.mediaView.bounds

                            player.play()
                            avPlayerAdded = true
                        }
                        
                    } else {
                        
                        let imageView = UIImageView(frame: cell.mediaView.bounds)
                       
                        imageView.af_setImage(withURL: URL(string: mediaUrl)!, filter: AspectScaledToFillSizeFilter(size: imageView.frame.size), imageTransition: .crossDissolve(0.1))
                        
                        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(showDetailImage))
                        doubleTapGesture.numberOfTapsRequired = 2
                        imageView.isUserInteractionEnabled = true
                        imageView.addGestureRecognizer(doubleTapGesture)
                        
                        cell.mediaView.addSubview(imageView)
                        
                    }

                }
                
                if let postAuthor = post.author, let placeName = post.placeName, let placeId = post.placeId{
                    
                    if let postAuthorProfilePictureUrl = postAuthor.profilePictureUrl, let postAuthorFirstName = postAuthor.firstName, let postAuthorLastName = postAuthor.lastName {
                        
                        //Strings
                        let nameString = NSAttributedString(string: postAuthorFirstName + " " + postAuthorLastName, attributes: [NSForegroundColorAttributeName: UIColor.white.flat, NSFontAttributeName: UIFont.init(name: "Avenir-Heavy", size: 13.0)!])
                        
                        let placeString = NSAttributedString(string: placeName, attributes: [NSForegroundColorAttributeName: UIColor.white.flat, NSFontAttributeName: UIFont.init(name: "Avenir-Heavy", size: 12.0)!])
                
                        
                        let headerNameString = NSMutableAttributedString()
                        headerNameString.append(nameString)
                        
                        let headerPlaceString = NSMutableAttributedString()
                        headerPlaceString.append(placeString)
                        
                        //Header View
                        cell.headerAuthorLabel.user = postAuthor
                        cell.headerAuthorLabel.isUserInteractionEnabled = true
                        cell.headerAuthorLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToProfileController(_ :))))
                        
                        cell.headerImageView.user = postAuthor
                        cell.headerImageView.isUserInteractionEnabled = true
                        cell.headerImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToProfileController(_ :))))
                        cell.headerImageView.af_setImage(withURL: URL(string: postAuthorProfilePictureUrl)!, placeholderImage: UIImage(named: "person"), filter: AspectScaledToFillSizeCircleFilter(size: cell.headerImageView.frame.size), imageTransition: .crossDissolve(0.1))
                        
                        cell.headerAuthorLabel.attributedText = headerNameString
                        
                        cell.headerPlaceLabel.placeId = placeId
                        print(placeId)
                        cell.headerPlaceLabel.placeName = placeName
                        print(placeName)
                        cell.headerPlaceLabel.attributedText = headerPlaceString
                        print(headerPlaceString)
                        cell.headerPlaceLabel.isUserInteractionEnabled = true
                        cell.headerPlaceLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToPlaceController(_ :))))
                    }
                }
                
                if let likes = post.likes, let views = post.views{
                    
                    
                    cell.likePostButton.addTarget(self, action: #selector(DetailController.likePost), for: .touchUpInside)
                    cell.commentButton.addTarget(self, action: #selector(DetailController.commentOnPost), for: .touchUpInside)
                    
                    //Action View
                    if isALikedPost(post: post){
                        cell.likePostButton.setImage(UIImage(named: "likedIcon"), for: .disabled)
                        cell.likePostButton.isEnabled = false
                    }else{
                        cell.likePostButton.setImage(UIImage(named: "likeIcon"), for: .normal)
                        cell.likePostButton.isEnabled = true
                    }
                    
                    cell.likesLabel.text = getStringFromLargeNumber(number: likes)
                    cell.viewsLabel.text = getStringFromLargeNumber(number: views)
                }
            }
            
            return cell
            
        case 1:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell") as! CommentCell
            
            if !self.refreshControl.isRefreshing{
                
                let comment = comments[indexPath.row]
                
                if let firstName = comment.author?.firstName, let lastName = comment.author?.lastName, let authorProfilePictureUrl = comment.author?.profilePictureUrl, let content = comment.comment, let timeStamp = comment.timeStamp{
                    
                    //Comment Strings
                    let commentAuthorString = NSAttributedString(string: firstName + " " + lastName, attributes: [NSForegroundColorAttributeName: UIColor.white.flat, NSFontAttributeName: UIFont.init(name: "Avenir-Heavy", size: 13.0)!])
                    let commentContentString = NSAttributedString(string: content, attributes: [NSForegroundColorAttributeName: UIColor.white.flat, NSFontAttributeName: UIFont.init(name: "Avenir-Heavy", size: 12.0)!])
                    let commentTimeStampString = NSAttributedString(string: " - " +  getDateStringFromDate(timeStamp), attributes: [NSForegroundColorAttributeName: UIColor.white.flat, NSFontAttributeName: UIFont.init(name: "Avenir-Heavy", size: 11.0)!])
                    
                    let commentString = NSMutableAttributedString()
                    commentString.append(commentAuthorString)
                    commentString.append(commentTimeStampString)
                    
                    let commentDetailString = NSMutableAttributedString()
                    commentDetailString.append(commentContentString)
                    
                    //Views
                    cell.commentAuthorLabel.user = comment.author
                    cell.commentAuthorLabel.isUserInteractionEnabled = true
                    cell.commentAuthorLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToProfileControllerFromComment(_ :))))
                    
                    cell.commentUserImageView.user = comment.author
                    cell.commentUserImageView.isUserInteractionEnabled = true
                    cell.commentUserImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToProfileControllerFromComment(_ :))))
                    cell.commentUserImageView.af_setImage(withURL: URL(string: authorProfilePictureUrl)!, placeholderImage: UIImage(named: "person"), filter: AspectScaledToFillSizeCircleFilter(size: cell.commentUserImageView.frame.size), imageTransition: .crossDissolve(0.1))
      
                    cell.commentDetailButton.comment = comment
                    cell.commentDetailButton.addTarget(self, action: #selector(showMoreCommentActionsAlertController(_ :)), for: .touchUpInside)
                    
                    cell.commentAuthorLabel.attributedText = commentString
                    cell.commentLabel.attributedText = commentDetailString
                }
            }
            
            return cell
            
        default:
            
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section{
        case 0:
            return 1
        case 1:
            return comments.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let section = indexPath.section
        
        switch section{
        case 0:
            return self.view.bounds.size.width
        case 1:
            return UITableViewAutomaticDimension
        default:
            return UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("cell is selected")
        
        if self.player.rate == 0 {
            self.player.play()
        } else {
            self.player.pause()
        }
        
        if self.player.rate >= 1 {
            self.player.seek(to: CMTimeMakeWithSeconds(0, 1))
            self.player.play()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    //MARK: - Post Action Methods
    func showDetailImage(){
        
        guard let mediaUrl = post.mediaUrl else{
            return
        }
        
//        self.showDetailImageController(mediaUrl)
    }
    
    func likePost(){
        
        guard let postId = post.id else{
            Drop.down(" : ( There was an error liking this post. Please try again.", state: Custom.error)
            return
        }
        
        let postQuery = PFQuery(className: "Post")
        postQuery.whereKey("objectId", equalTo: postId)
        postQuery.limit = 1
        postQuery.findObjectsInBackground(block: {(objects: [PFObject]?, error: Error?) -> Void in
            if let error = error{
                Drop.down(" : ( There was an error liking this post. Please try again.", state: Custom.error)

                print(error)
            }else{
                if !(objects?.isEmpty)!{
                    
                    for object in objects!{
                        
                        let likes = object["likes"] as? Int
                        
                        object["likes"] = likes! + 1
                        if (self.canLike == true) {
                            object.saveInBackground(block: {(success: Bool, error: Error?) -> Void in
                                if success{
                                    
                                    if self.post.author?.objectId != ChoozyUser.current()?.objectId{
                                        //                                    self.sendLikeNotification()
                                    }
                                    
                                    Drop.down(" : ) Thanks for liking this post", state: Custom.complete)
                                    self.post.likes = likes! + 1
                                    //                                self.showLikeAnimation()
                                    //                                self.saveLikedPost(post: self.post)
                                    self.disableLike()
                                    DispatchQueue.main.async(execute: {
                                        self.detailTableView.reloadData()
                                    })
                                    
                                    
                                }else if let error = error{
                                    Drop.down(" : ( There was an error liking this post. Please try again.", state: Custom.error)
                                    print(error)
                                }else{
                                    Drop.down(" : ( There was an error liking this post. Please try again.", state: Custom.error)
                                    
                                }
                            })
                        }
                        
                    }
                    
                }else{
                    Drop.down(" : ( There was an error liking this post. Please try again.", state: Custom.error)
                }
            }
        })
    }
    func disableLike(){
        canLike = false
    }
//    
//    func showLikeAnimation(){
//        for _ in 1...30{
//            let floatingAnimation = JRMFloatingAnimationView(starting: self.view.center)
//            floatingAnimation?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
//            floatingAnimation?.add(UIImage(named: "likedIcon"))
//            floatingAnimation?.fadeOut = true
//            floatingAnimation?.varyAlpha = true
//            floatingAnimation?.animationDuration = 3.0
//            floatingAnimation?.floatingShape = .curveRight
//            floatingAnimation?.removeOnCompletion = true
//            floatingAnimation?.animate()
//            self.view.addSubview(floatingAnimation!)
//        }
//    }
//    
//    func sendLikeNotification(){
//        
//        guard
//            let postId = post.id,
//            let postAuthorId = post.author?.objectId,
//            let postSubAddress = post.subAddress,
//            let postAddress = post.address,
//            let postCity = post.city,
//            let postState = post.state,
//            let postLikeCount = post.likes
//        
//            
//            
//            
//            else{
//                return
//        }
//    }
//
//        PFCloud.callFunction(inBackground: "sendLikeNotification", withParameters: ["postId": postId, "postAuthorId": postAuthorId, "postSubAddress": postSubAddress, "postAddress": postAddress, "postCity": postCity, "postState": postState], block: {(response: Any?, error: Error?) in
//            
//            if let error = error{
//                print(error)
//            }else{
//                print(response as! String)
//                if response as! String == "1"{
//                    print("Push notification successfully sent to: \(postAuthorId)")
//                }else{
//                    print("Push notification failed to send to: \(postAuthorId) with error \(error)")
//                }
//            }
//        })
//    }

    func increaseViewCount(post: Post, amount: Int){
        
        guard let postId = post.id else{
            print("guard let postId failed in increaseViewCount()")
            return
        }
        
        let postQuery = PFQuery(className: "Post")
        postQuery.whereKey("objectId", equalTo: postId)
        postQuery.limit = 1
        postQuery.findObjectsInBackground(block: {(objects: [PFObject]?, error: Error?) -> Void in
            if let error = error{
                print(error)
                print("postQuery.findObjectsInBackground failed in increaseViewCount()")
            }else{
                if !(objects?.isEmpty)!{
                    
                    for object in objects!{
                        
                        let views = object["views"] as? Int
                        
                        object["views"] = views! + amount
                        object.saveInBackground(block: {(success: Bool, error: Error?) -> Void in
                            if success{
                                
                                self.post.views = views! + amount
                                
                                DispatchQueue.main.async(execute: {
                                    self.detailTableView.reloadData()
                                })
                                
                            }else if let error = error{
                                print("error in increaseViewCount()")
                                print(error)
                            }else{
                                print("uknown error in increaseViewCount()")
                            }
                        })
                    }
                    
                }else{
                    print("increaseViewCount() - objects?.isEmpty == true")
                }
            }
        })
    }
    
    func commentOnPost(){
        
        guard
            let userFirstName = ChoozyUser.current()?.firstName,
            let userLastName = ChoozyUser.current()?.lastName
            else{
                return
        }
        
        let alertView = SCLAlertView()
        
        let textField = alertView.addTextField("Leave a comment...")
        textField.autocapitalizationType = .sentences
        textField.delegate = self
        
        alertView.addButton("Send") {
            
            guard let comment = textField.text else{
                Drop.down(" : ( There was an error trying to leave a comment.", state: Custom.error)
                return
            }
            
            if !comment.isEmpty(){
                if !comment.containsInvalidCharacters(){
                    
                    /**
                     * The comment is not empty, nor
                     * does it contain any profanity.
                     * The action now would be to save the comment.
                     */
                    self.saveComment(post: self.post, content: comment)
                    
                }else{
                    let appearance = SCLAlertView.SCLAppearance(
                        showCloseButton: false
                    )
                    
                    let alertView = SCLAlertView(appearance: appearance)
                    alertView.addButton("Okay") {
                        self.commentOnPost()
                    }
                    
                    alertView.showTitle("Whoa there!", subTitle: "\n Please don't use any profanity. \n", style: .info, closeButtonTitle: "", duration: 0.0, colorStyle: UIColor.purple.hex.flat, colorTextButton: 0xECF0F1, circleIconImage: UIImage(named: "commentIcon"), animationStyle: .leftToRight)
                }
            }else{
                let appearance = SCLAlertView.SCLAppearance(
                    showCloseButton: false
                )
                
                let alertView = SCLAlertView(appearance: appearance)
                alertView.addButton("Okay") {
                    self.commentOnPost()
                }
                
                alertView.showTitle("Whoa there!", subTitle: "\n You can't leave an empty comment! \n", style: .info, closeButtonTitle: "", duration: 0.0, colorStyle: UIColor.purple.hex.flat, colorTextButton: 0xECF0F1, circleIconImage: UIImage(named: "commentIcon"), animationStyle: .leftToRight)
            }
        }
        
        alertView.showTitle("", subTitle: "Leave a Comment as \n \(userFirstName) \(userLastName) \n", style: .edit, closeButtonTitle: "Cancel", duration: 0.0, colorStyle: UIColor.purple.hex.flat, colorTextButton: 0xECF0F1, circleIconImage: UIImage(named: "commentIcon"), animationStyle: .leftToRight)
        
    }
    
    func saveComment(post: Post, content: String){
        
        let comment = Comment()
        comment["author"] = ChoozyUser.current()
        comment["postId"] = post.id
        comment["comment"] = content
        comment.saveInBackground(block: {(success: Bool, error: Error?) -> Void in
            if success{
                Drop.down(" : ) Thanks for leaving your comment.", state: Custom.complete)
                self.refreshAllData()
            }
            else if let error = error{
                Drop.down(" : ( There was an error trying to leave a comment.", state: Custom.error)
                print(error)
            }else{
                Drop.down(" : ( There was an error trying to leave a comment.", state: Custom.error)
                print("Something else went wrong when saving COMMENT")
            }
        })
    }
    
    func sharePost(){
        
        guard
            let postMediaUrl = post.mediaUrl,
            let state = post.state,
            let city = post.city,
            let address = post.address,
            let subAddress = post.subAddress
            else{
                return
        }
        
        Alamofire.request(postMediaUrl, method: .get).responseImage { response in
            guard let postImage = response.result.value else {
                return
            }
            
            let postContentString = "\nCheck out this place at " + getAddressString(subAddress: subAddress, address: address, city: city, state: state) + ". You can see this and more on Choozy. Grab it at: \n \n" + "google.com"
            
            let activityController = UIActivityViewController(activityItems: [postImage, postContentString], applicationActivities: nil)
            activityController.excludedActivityTypes = [.addToReadingList, .airDrop, .assignToContact, .openInIBooks, .postToTencentWeibo, .postToVimeo, .postToWeibo]
            activityController.popoverPresentationController?.sourceView = self.view
            activityController.popoverPresentationController?.sourceRect = self.view.bounds
            self.present(activityController, animated: true, completion: nil)
            
        }
    }
    
    //MARK: More Options UIAlertController
    func showMoreOptionsAlertController(){
        
        let isSelf = post.author?.objectId == ChoozyUser.current()?.objectId
        
        let alertController = UIAlertController(title: "\n More Options", message: "", preferredStyle: .actionSheet)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        
        let reportAction = UIAlertAction(title: "Report as Inaccurate or Inappropriate", style: .destructive, handler: { (action: UIAlertAction!) -> () in
            self.reportPost()
        })
        
        let navigateAction = UIAlertAction(title: "Open in Maps", style: .default, handler: { (action: UIAlertAction!) -> () in
            self.openPostInMaps()
        })
        
        let deletePostAction: UIAlertAction = UIAlertAction(title: "Delete my Post", style: .destructive, handler: { (action: UIAlertAction!) -> () in
            
            let alertView = SCLAlertView()
            alertView.addButton("Yes") {
                self.deletePost()
            }
            alertView.showTitle("Hey!", subTitle: "\n Are you absolutely sure you want to delete this Post? \n\n This cannot be undone. \n", style: .info, closeButtonTitle: "No", duration: 0.0, colorStyle: UIColor.purple.hex.flat, colorTextButton: 0xECF0F1, circleIconImage: UIImage(named: "alertPinIcon"), animationStyle: .leftToRight)
        })
        
        if isSelf {
            alertController.addAction(deletePostAction)
            alertController.addAction(navigateAction)
            alertController.addAction(dismissAction)
        }else{
            alertController.addAction(reportAction)
            alertController.addAction(navigateAction)
            alertController.addAction(dismissAction)
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: Methods available in the MoreOptionsUIAlertController
    func reportPost(){
        
        guard let id = post.id else{
            return
        }
        
        if !self.isAReportedPost(post: post){
            let reportedPostQuery = PFQuery(className: "ReportedPost")
            reportedPostQuery.whereKey("postId", equalTo: id)
            reportedPostQuery.limit = 1
            reportedPostQuery.findObjectsInBackground(block: {(objects: [PFObject]?, error: Error?) -> Void in
                
                if let error = error{
                    print(error)
                    Drop.down(" : ( There was an error while trying to report this Post. Try again.", state: Custom.error)
                }else{
                    
                    /** We first need to find a row with a postId equal to the Post.id.
                     *  If we find a row, we need to check if it is a candidate for auto-deletion.
                     *  If so, delete it, otherwise we need to increase it's ReportedCount by 1.
                     */
                    if !(objects?.isEmpty)!{
                        
                        for object in objects!{
                            
                            let reportedCount = object["reportedCount"] as! Int
                            
                            /** We first need to check
                             *   if our reportCount is elligible for auto-deletion.
                             *   This is defined as having a reportCount greater than
                             *   the number we set here.
                             */
                            if reportedCount >= appDefaults.minimumReportedCount{
                                object.deleteInBackground(block: {(success: Bool, error: Error?) -> Void in
                                    if let error = error{
                                        print(error)
                                        Drop.down(" : ( There was an error while trying to report this Post. Try again.", state: Custom.error)
                
                                    }else{
                                        if success{
                                            Drop.down(" : ) Thanks for reporting this Post. We went ahead and removed it.", state: Custom.complete)
                                            self.returnToViewController()
                                            
                                            
                                        }else{
                                            Drop.down(" : ( There was an error while trying to report this Post. Try again.", state: Custom.error)
                                   
                                        }
                                    }
                                })
                                
                                /** If the reportCount is less than 5,
                                 *  it is not a candidate for auto-deletion.
                                 *  We should only increase the reportCount by 1.
                                 */
                            }else{
                                object["reportedCount"] = reportedCount + 1
                                object.saveInBackground(block: {(success: Bool, error: Error?) -> Void in
                                    if let error = error{
                                        print(error)
                                        Drop.down(" : ( There was an error while trying to report this Post. Try again.", state: Custom.error)
                                       
                                    }else{
                                        if success{
                                            Drop.down(" : ) Thanks for reporting this Post. We are looking into it.", state: Custom.complete)
//                                            self.saveReportedPost(post: self.post)
                         
                                            
                                        }else{
                                            Drop.down(" : ( There was an error while trying to report this Post. Try again.", state: Custom.error)
                                            
                                        }
                                    }
                                })
                            }
                        }
                        
                        /** If we didn't find a row matching this particular query, we need to
                         *  create a row in the ReportedPost class, with a postId equal to the Post.id
                         *  and a reportedCount as 1 to account for the newly reported Post.
                         */
                    }else{
                        let reportedObject = PFObject(className: "ReportedPost")
                        reportedObject["postId"] = id
                        reportedObject["reportedCount"] = 1
                        reportedObject.saveInBackground(block: {(success: Bool, error: Error?) -> Void in
                            if let error = error{
                                print(error)
                                Drop.down(" : ( There was an error while trying to report this Post. Try again.", state: Custom.error)
                          
                            }else{
                                if success{
                                    Drop.down(" : ) Thanks for reporting this Post. We are looking into it.", state: Custom.complete)
//                                    self.saveReportedPost(post: self.post)
                            
                                    
                                }else{
                                    Drop.down(" : ( There was an error while trying to report this Post. Try again.", state: Custom.error)
                                   
                                }
                            }
                        })
                    }
                }
            })
        }else{
            
            let alertView = SCLAlertView()
            
            alertView.showTitle("Whoops!", subTitle: "\n It looks liked you've already reported this post! We're looking into it. \n", style: .info, closeButtonTitle: "Okay", duration: 0.0, colorStyle: UIColor.purple.hex.flat, colorTextButton: 0xECF0F1, circleIconImage: UIImage(named: "alertPinIcon"), animationStyle: .leftToRight)
        }
    }
    
    func deletePost(){
        
        guard let postId = post.id else{
            return
        }
        
        let object = PFObject(withoutDataWithClassName: "Post", objectId: postId)
        object.deleteInBackground(block: {(success: Bool, error: Error?) -> Void in
            if let error = error{
                print(error)
                Drop.down(" : ( There was an error while trying to delete your Post. Try again.", state: Custom.error)
    
            }else{
                if success{ //The post was deleted, now we need to attempt to deleted the post' associated comments.
                    
                    let commentsQuery = PFQuery(className: "Comment")
                    commentsQuery.whereKey("postId", equalTo: postId)
                    commentsQuery.limit = 1000
                    commentsQuery.findObjectsInBackground(block: {(objects: [PFObject]?, error: Error?) -> Void in
                        
                        if let error = error{ //Comments were not deleted, but the post still was.
                            print(error)
                            Drop.down(" : ) Your Post was successfully deleted.", state: Custom.complete)
                            self.returnToViewController()
                 
                        }else{
                            if !(objects?.isEmpty)!{
                                
                                for (index, object) in objects!.enumerated() {
                                    
                                    object.deleteInBackground(block: {(success: Bool, error: Error?) -> Void in
                                        
                                        if let error = error{ //Comments were not deleted, but the post still was.
                                            print(error)
                                            Drop.down(" : ) Your Post was successfully deleted.", state: Custom.complete)
                                            self.returnToViewController()
                           
                                        }else{
                                            if success{ //A comment was successfully deleted.
                                                
                                                if index == (objects?.count)! - 1{
                                                    Drop.down(" : ) Your Post was successfully deleted.", state: Custom.complete)
                                                    self.returnToViewController()
                                          
                                                }
                                            }
                                        }
                                    })
                                }
                                
                            }else{
                                Drop.down(" : ) Your Post was successfully deleted.", state: Custom.complete)
                                self.returnToViewController()
                         
                            }
                        }
                    })
                    
                }else{
                    Drop.down(" : ( There was an error while trying to delete your Post. Try again.", state: Custom.error)
                }
            }
        })
    }
    
    func openPostInMaps(){
        
        guard let latitude = self.post.location?.latitude, let longitude = self.post.location?.longitude else{
            return
        }
        
        openCoordinateInMap(latitude, longitude: longitude)
    }
    
    func isALikedPost(post: Post) -> Bool{
        return false
    }
    
    func isAReportedPost(post: Post) -> Bool{
        return false
    }
    
    func isAReportedComment(comment: Comment) -> Bool{
        return true
    }
    
    
    //MARK: Show More Options Comments Alert Controller
    func showMoreCommentActionsAlertController(_ sender: CommentDetailButton){
        
        guard let comment = sender.comment else{
            print("can't find comment from comment")
            return
        }
        
        let isSelf = comment.author?.objectId == ChoozyUser.current()?.objectId
        
        let alertController = UIAlertController(title: "\n More Options", message: "", preferredStyle: .actionSheet)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        
        let reportAction = UIAlertAction(title: "Report as Inappropriate", style: .destructive, handler: { (action: UIAlertAction!) -> () in
            self.reportComment(comment: comment)
        })
        
        let deleteCommentAction: UIAlertAction = UIAlertAction(title: "Delete my Comment", style: .destructive, handler: { (action: UIAlertAction!) -> () in
            
            let alertView = SCLAlertView()
            alertView.addButton("Yes") {
                self.deleteComment(comment: comment)
            }
            alertView.showTitle("Hey!", subTitle: "\n Are you sure you want to delete your comment? \n\n This cannot be undone. \n", style: .info, closeButtonTitle: "No", duration: 0.0, colorStyle: UIColor.purple.hex.flat, colorTextButton: 0xECF0F1, circleIconImage: UIImage(named: "alertPinIcon"), animationStyle: .leftToRight)
            
        })
        
        if isSelf {
            alertController.addAction(deleteCommentAction)
            alertController.addAction(dismissAction)
        }else{
            alertController.addAction(reportAction)
            alertController.addAction(dismissAction)
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: More Options Methods called in the showMoreCommentActionsAlertController
    func deleteComment(comment: Comment){
        
        guard let commentId = comment.id else{
            print("got a nil comment id")
            return
        }
        
        let object = PFObject(withoutDataWithClassName: "Comment", objectId: commentId)
        object.deleteInBackground(block: {(success: Bool, error: Error?) -> Void in
            if let error = error{
                print(error)
                Drop.down(" : ( There was an error while trying to delete your Comment. Try again.", state: Custom.error)
       
            }else{
                if success{
                    Drop.down(" : ) Your Comment was successfully deleted.", state: Custom.complete)
                    self.refreshAllData()
      
                }else{
                    Drop.down(" : ( There was an error while trying to delete your Comment. Try again.", state: Custom.error)
                 
                }
            }
        })
    }
    
    func reportComment(comment: Comment){
        
        guard let id = comment.id else{
            return
        }
        
        if !self.isAReportedComment(comment: comment){
            let reportedCommentQuery = PFQuery(className: "ReportedComment")
            reportedCommentQuery.whereKey("commentId", equalTo: id)
            reportedCommentQuery.limit = 1
            reportedCommentQuery.findObjectsInBackground(block: {(objects: [PFObject]?, error: Error?) -> Void in
                
                if let error = error{
                    print(error)
                    Drop.down(" : ( There was an error while trying to report this Comment. Try again.", state: Custom.error)
               
                }else{
                    
                    /** We first need to find a row with a commentId equal to the Comment.id.
                     *  If we find a row, we need to check if it is a candidate for auto-deletion.
                     *  If so, delete it, otherwise we need to increase it's ReportedCount by 1.
                     */
                    if !(objects?.isEmpty)!{
                        
                        for object in objects!{
                            
                            let reportedCount = object["reportedCount"] as! Int
                            
                            /** We first need to check
                             *   if our reportCount is elligible for auto-deletion.
                             *   This is defined as having a reportCount greater than
                             *   the number we set here.
                             */
                            if reportedCount >= appDefaults.minimumReportedCount{
                                object.deleteInBackground(block: {(success: Bool, error: Error?) -> Void in
                                    if let error = error{
                                        print(error)
                                        Drop.down(" : ( There was an error while trying to report this Comment. Try again.", state: Custom.error)
                                       
                                    }else{
                                        if success{
                                            Drop.down(" : ) Thanks for reporting this Comment. We went ahead and removed it.", state: Custom.complete)
                                            self.refreshAllData()
                                
                                            
                                        }else{
                                            Drop.down(" : ( There was an error while trying to report this Comment. Try again.", state: Custom.error)
                                        }
                                    }
                                })
                                
                                /** If the reportCount is less than 5,
                                 *  it is not a candidate for auto-deletion.
                                 *  We should only increase the reportCount by 1.
                                 */
                            }else{
                                object["reportedCount"] = reportedCount + 1
                                object.saveInBackground(block: {(success: Bool, error: Error?) -> Void in
                                    if let error = error{
                                        print(error)
                                        Drop.down(" : ( There was an error while trying to report this Comment. Try again.", state: Custom.error)
                                    
                                    }else{
                                        if success{
                                            Drop.down(" : ) Thanks for reporting this Comment. We are looking into it.", state: Custom.complete)
//                                            self.saveReportedComment(comment: comment)
                                        
                                            
                                        }else{
                                            Drop.down(" : ( There was an error while trying to report this Comment. Try again.", state: Custom.error)
                                      
                                        }
                                    }
                                })
                            }
                        }
                        
                        /** If we didn't find a row matching this particular query, we need to
                         *  create a row in the ReportedPost class, with a postId equal to the Post.id
                         *  and a reportedCount as 1 to account for the newly reported Post.
                         */
                    }else{
                        let reportedObject = PFObject(className: "ReportedComment")
                        reportedObject["commentId"] = id
                        reportedObject["reportedCount"] = 1
                        reportedObject.saveInBackground(block: {(success: Bool, error: Error?) -> Void in
                            if let error = error{
                                print(error)
                                Drop.down(" : ( There was an error while trying to report this Comment. Try again.", state: Custom.error)
                      
                            }else{
                                if success{
                                    Drop.down(" : ) Thanks for reporting this Comment. We are looking into it.", state: Custom.complete)
//                                    self.saveReportedComment(comment: comment)
                      
                                    
                                }else{
                                    Drop.down(" : ( There was an error while trying to report this Comment. Try again.", state: Custom.error)
                              
                                }
                            }
                        })
                    }
                }
            })
        }else{
            
            let alertView = SCLAlertView()
            
            alertView.showTitle("Whoops!", subTitle: "\n It looks liked you've already reported this comment! We're looking into it. \n", style: .info, closeButtonTitle: "Okay", duration: 0.0, colorStyle: UIColor.purple.hex.flat, colorTextButton: 0xECF0F1, circleIconImage: UIImage(named: "alertPinIcon"), animationStyle: .leftToRight)
        }
        
    }
    
    //MARK: - Refresh Control Methods
    func refreshAllDataFromRefresh(){
        
        comments.removeAll()
        
        loadPostData(post: post)
        setupTitle(post: post)
        loadComments(post: post)
    }
    
    func loadPostData(post: Post){
        
        guard let postId = post.id else{
            return
        }
        
        let postsQuery = PFQuery(className: "Post")
        postsQuery.includeKeys(["author"])
        postsQuery.whereKey("objectId", equalTo: postId)
        postsQuery.limit = 1
        postsQuery.findObjectsInBackground(block: {(objects: [PFObject]?, error: Error?) -> Void in
            if let error = error{
                print(error)
                Drop.down(" : ( There was an error refreshing this Post. Please try again.", state: Custom.error)
            }else{
                if !(objects?.isEmpty)!{
                    
                    for object in objects!{
                        
                        guard
                            let likes = object["likes"] as? Int,
                            let views = object["views"] as? Int
                            else{
                                continue
                        }
                        
                        post.likes = likes
                        post.views = views
                    }
                }
            }
        })
    }
    
    //MARK: - Navigation Methods
    func goToProfileController(_ gesture: UITapGestureRecognizer){
        
        if let choozyImageView = gesture.view as? ChoozyUserImageView {
            if let user = choozyImageView.user{
                self.showProfileController(user)
            }
        }else if let choozyLabel = gesture.view as? ChoozyUserLabel {
            if let user = choozyLabel.user{
                self.showProfileController(user)
            }
        }
    }
    
    func goToPlaceController(_ gesture: UITapGestureRecognizer){
        if let choozyPlaceLabel = gesture.view as? ChoozyPlaceLabel {
            if let placeId = choozyPlaceLabel.placeId, let placeName = choozyPlaceLabel.placeName {
                self.showPlaceController(placeId, placeName: placeName)
            }
        }
    }

    func goToProfileControllerFromComment(_ gesture: UITapGestureRecognizer){
        
        if let choozyImageView = gesture.view as? ChoozyUserImageView {
            if let user = choozyImageView.user{
                self.showProfileController(user)
            }
        }else if let choozyLabel = gesture.view as? ChoozyUserLabel {
            if let user = choozyLabel.user{
                self.showProfileController(user)
            }
        }
    }
    
    func returnToViewController(){
        _ = self.navigationController?.popToRootViewController(animated: true)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshAllData"), object: nil, userInfo: nil)
    }
    
    //MARK: - Prepare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "places"{
            let placeController: PlaceController = segue.destination as! PlaceController
            placeController.place = sender as? (String, String)
        }
        
        if segue.identifier == "profile" {
            let profileController: ProfileController = segue.destination as! ProfileController
            profileController.user = (sender as? ChoozyUser)!
            
        }
        
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
    }
    
    //MARK: - TextField Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    //MARK: - Status Bar
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
}
