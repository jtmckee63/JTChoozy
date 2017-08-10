//
//  NewPostController.swift
//
//
//  Created by Cameron Eubank on 3/6/17.
//
//

import UIKit
import CoreLocation
import Parse
import MobileCoreServices
import MediaPlayer
import AlamofireImage
import AVKit
import AVFoundation
import SCLAlertView
import SwiftyDrop
import GooglePlaces


class NewPostController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate  {
    
    @IBOutlet var postTableView: UITableView!
    
    var postImage = UIImage()
    var originalImage = UIImage()
    var locationManager = CLLocationManager()
    var hasTakenPhoto = Bool()
    //JT added
    var hasTakenVideo = Bool()
    var commentContent = String()
    
    //JT added for video
    @IBOutlet var mediaView: UIView!
    var moviePlayerController = MPMoviePlayerController()
    var defaultCameraImage = UIImage(named: "cameraImage")
    var selectedMovieURL: URL?
    var selectedImageFromPicker: UIImage?
    
    var player = AVPlayer()
    var playerLayer = AVPlayerLayer()
    //JT added for place new post
    var thePlace = Place()
    var placeLat = Double()
    var placeLog = Double()
    
    
    

    //colors JT
    var lightBlue = UIColor(red:0.42, green:0.93, blue:1.00, alpha:1.0)
    var blurple = UIColor(red:0.25, green:0.00, blue:1.00, alpha:1.0)
    var lightGreen = UIColor(red:0.05, green:1.00, blue:0.00, alpha:1.0)
    var black: UIColor = UIColor.black
    let darkGray = UIColor(red:0.25, green:0.25, blue:0.25, alpha:1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Background Color
//        self.view.backgroundColor = UIColor.blue.light
        self.view.backgroundColor = black
        //Post Table View
//        postTableView.backgroundColor = UIColor.blue.light
        postTableView.backgroundColor = darkGray

        postTableView.delegate = self
        postTableView.dataSource = self
        postTableView.separatorStyle = .none
        postTableView.indicatorStyle = .white
        postTableView.register(UINib(nibName: "PostMediaViewCell", bundle: nil), forCellReuseIdentifier: "postMediaViewCell")
        postTableView.register(UINib(nibName: "PlacesCell", bundle: nil), forCellReuseIdentifier: "placesCell")
        postTableView.register(UINib(nibName: "PostCommentCell", bundle: nil), forCellReuseIdentifier: "postCommentCell")
        postTableView.register(UINib(nibName: "PostButtonCell", bundle: nil), forCellReuseIdentifier: "postButtonCell")
//        postTableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleImageViewTapped)))
        postTableView.isUserInteractionEnabled = true
        postTableView.contentMode = .scaleAspectFill
        
        //Set Default Variables
        hasTakenPhoto = false
        hasTakenVideo = false
        
        //fix constraint 
//        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        //Add Observers for keyboardWillShow && keyBoardWillHide
        NotificationCenter.default.addObserver(self, selector: #selector(NewPostController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NewPostController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        //Down Gesture Recognizer to dismiss the view controller.
        let downGesture = UISwipeGestureRecognizer(target: self, action: #selector(dismissViewController))
        downGesture.direction = .down
        self.view.addGestureRecognizer(downGesture)
        
        //Open the Camera
        openCamera()
        
        
    }
    
    func handleImageViewTapped() {
        if postImage == defaultCameraImage{
            openCamera()
        }
    }
    
    func createPost(_ postButton: UIButton){
        if !commentContent.isEmpty{
            
            if !commentContent.containsInvalidCharacters(){
                
                //Notify the user that posting is in progress.
                Drop.down(" Posting...", state: Custom.fetching)
                postButton.isEnabled = false
                
                let takenLocation = locationManager.getCurrentLocationCoordinates()
                
                print(self.placeLat)
                print(self.placeLog)
                
                let takenLoc = PFGeoPoint(latitude: takenLocation.latitude, longitude: takenLocation.longitude)
                let placeLocation = PFGeoPoint(latitude: self.placeLat, longitude: self.placeLog)
                let distance = takenLoc.distanceInMiles(to: placeLocation)
                print("distance ::::", distance)
                
                
                getLocationDictionary(location: CLLocation(latitude: takenLocation.latitude, longitude: takenLocation.longitude),
                                      completion:({(location) in
                                        
                                        let randomPostId = UUID().uuidString
                                        
                                        //JT comment out cam code
                                    
                                        
                                        if self.selectedMovieURL != nil{
                                            if let postURL = self.selectedMovieURL{
                                                let mediaData = try! Data(contentsOf: postURL)
                                                let postMedia = PFFile(name: "post_" + randomPostId + ".mov", data: mediaData)
                                                print("inside post movie method")
                                                postMedia?.saveInBackground(block: {(success: Bool, error: Error?) -> Void in
                                                    
                                                    if let error = error{
                                                        
                                                        /**
                                                         * There was an error while saving the PFFile.
                                                         * We now need to alert the user
                                                         * and allow the user to post again.
                                                         */
                                                        print(error)
                                                        
                                                        Drop.down(" There was an error with your Post. Try again. ", state: Custom.error)
                                                        postButton.isEnabled = true
                                                        
                                                    }else{
                                                        
                                                        
                                                        if success{
                                                            
                                                            /**
                                                             * At this point we have successfully created and saved a PFFile.
                                                             * We now need to save a Post and a Comment.
                                                             */

                                                            
                                                            let mediaUrl = postMedia?.url
                                                            let placeId = self.selectedPlace.id!
                                                            let placeName = self.selectedPlace.name!

                                                            
                                                            
                                                            let post = Post()
                                                            post["likes"] = 0
                                                            post["views"] = 0
                                                            post["subAddress"] = location["subAddress"]
                                                            post["address"] = location["address"]
                                                            post["city"] = location["city"]
                                                            post["state"] = location["state"]
                                                            post["country"] = location["country"]
                                                            post["location"] = PFGeoPoint(latitude: takenLocation.latitude, longitude: takenLocation.longitude)
                                                            post["author"] = ChoozyUser.current()
                                                            post["authorId"] = ChoozyUser.current()?.objectId
                                                            post["mediaUrl"] = mediaUrl
                                                            post["placeId"] = placeId
                                                            post["placeName"] = placeName
                                                            
                                                            if (distance < 0.1) {
                                                                Drop.down(" You are not near this place :( ", state: Custom.error)
                                                                self.deletePost(post: post)
                                                                postButton.isEnabled = true
                                                            } else {
                                                                post.saveInBackground(block: {(success: Bool, error: Error?) -> Void in
                                                                    
                                                                    if success{
                                                                        
                                                                        /**
                                                                         * At this point we have successfully created and saved a Post.
                                                                         * We now need to save a Comment.
                                                                         */
                                                                        
                                                                        let comment = Comment()
                                                                        comment["author"] = ChoozyUser.current()
                                                                        comment["postId"] = post.objectId
                                                                        comment["comment"] = self.commentContent
                                                                        comment.saveInBackground(block: {(success: Bool, error: Error?) -> Void in
                                                                            
                                                                            if success{
                                                                                
                                                                                /**
                                                                                 * At this point we have successfully created and saved a Post, and Comment.
                                                                                 * This is our end goal. ⭐️⭐️⭐️⭐️⭐️
                                                                                 * We now need to dismiss the NewPostController
                                                                                 * and show the new Post on the mapView.
                                                                                 */
                                                                                
                                                                                Drop.down(" Thanks for posting! ", state: Custom.complete)
                                                                                postButton.isEnabled = true
                                                                                
                                                                                //Refresh our Data after we add a new post.
                                                                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "addPostAfterPosting"), object: nil, userInfo: ["postId": post.objectId! as String])
                                                                                
                                                                                self.dismissViewController()
                                                                            }
                                                                                
                                                                            else if let error = error{
                                                                                
                                                                                /**
                                                                                 * There was an error while saving the comment.
                                                                                 * We now need to alert the user, delete the post we just created (in the background),
                                                                                 * and allow the user to post again.
                                                                                 */
                                                                                print(error)
                                                                                
                                                                                Drop.down(" There was an error with your Post. Try again. ", state: Custom.error)
                                                                                self.deletePost(post: post)
                                                                                postButton.isEnabled = true
                                                                                
                                                                                
                                                                            }else{
                                                                                
                                                                                /**
                                                                                 * There was an error while saving the comment.
                                                                                 * We now need to alert the user, delete the post we just created (in the background),
                                                                                 * and allow the user to post again.
                                                                                 */
                                                                                
                                                                                Drop.down(" There was an error with your Post. Try again. ", state: Custom.error)
                                                                                self.deletePost(post: post)
                                                                                postButton.isEnabled = true
                                                                                
                                                                            }
                                                                        })
                                                                        
                                                                    }else if let error = error {
                                                                        
                                                                        /**
                                                                         * There was an error while saving the post.
                                                                         * We now need to alert the user
                                                                         * and allow the user to post again.
                                                                         */
                                                                        print(error)
                                                                        
                                                                        Drop.down(" There was an error with your Post. Try again. ", state: Custom.error)
                                                                        postButton.isEnabled = true
                                                                        
                                                                    }else{
                                                                        
                                                                        /**
                                                                         * There was an error while saving the post.
                                                                         * We now need to alert the user
                                                                         * and allow the user to post again.
                                                                         */
                                                                        
                                                                        Drop.down(" There was an error with your Post. Try again. ", state: Custom.error)
                                                                        postButton.isEnabled = true
                                                                        
                                                                    }
                                                                })
                                                            }
                                                        }
                                                    }
                                                })
                                            }
                                            
                                        }else{
                                            let mediaData = UIImageJPEGRepresentation(self.postImage, 0.8)!
                                            
                                            let postMedia = PFFile(name: "post_" + randomPostId + ".jpeg", data: mediaData)
                                            print("inside image post method")
                                            
                                            postMedia?.saveInBackground(block: {(success: Bool, error: Error?) -> Void in
                                                
                                                if let error = error{
                                                    
                                                    /**
                                                     * There was an error while saving the PFFile.
                                                     * We now need to alert the user
                                                     * and allow the user to post again.
                                                     */
                                                    print(error)
                                                    
                                                    Drop.down(" There was an error with your Post. Try again. ", state: Custom.error)
                                                    postButton.isEnabled = true
                                                    
                                                }else{
                                                    
                                                    if success{
                                                        
                                                        /**
                                                         * At this point we have successfully created and saved a PFFile.
                                                         * We now need to save a Post and a Comment.
                                                         */
                                                        
                                                        guard
                                                            let mediaUrl = postMedia?.url,
                                                            let placeId = self.selectedPlace.id,
                                                            let placeName = self.selectedPlace.name
                                                            else {
                                                                return
                                                        }

                                                        let post = Post()
                                                        post["likes"] = 0
                                                        post["views"] = 0
                                                        post["subAddress"] = location["subAddress"]
                                                        post["address"] = location["address"]
                                                        post["city"] = location["city"]
                                                        post["state"] = location["state"]
                                                        post["country"] = location["country"]
                                                        post["location"] = PFGeoPoint(latitude: takenLocation.latitude, longitude: takenLocation.longitude)
                                                        post["author"] = ChoozyUser.current()
                                                        post["authorId"] = ChoozyUser.current()?.objectId
                                                        post["mediaUrl"] = mediaUrl
                                                        post["placeId"] = placeId
                                                        post["placeName"] = placeName
                                                        //DISTANCE TO PLACE NEW POSTS 0.03
                                                        print("this is the distance ***************_________________*****************", distance)
                                                        if (distance > 0.09) {
                                                            Drop.down(" You are not near this place :( ", state: Custom.error)
                                                            self.deletePost(post: post)
                                                            postButton.isEnabled = true
                                                        } else {
                                                            post.saveInBackground(block: {(success: Bool, error: Error?) -> Void in
                                                                
                                                                if success{
                                                                    
                                                                    /**
                                                                     * At this point we have successfully created and saved a Post.
                                                                     * We now need to save a Comment.
                                                                     */
                                                                    
                                                                    let comment = Comment()
                                                                    comment["author"] = ChoozyUser.current()
                                                                    comment["postId"] = post.objectId
                                                                    comment["comment"] = self.commentContent
                                                                    comment.saveInBackground(block: {(success: Bool, error: Error?) -> Void in
                                                                        
                                                                        if success{
                                                                            
                                                                            /**
                                                                             * At this point we have successfully created and saved a Post, and Comment.
                                                                             * This is our end goal. ⭐️⭐️⭐️⭐️⭐️
                                                                             * We now need to dismiss the NewPostController
                                                                             * and show the new Post on the mapView.
                                                                             */
                                                                            
                                                                            Drop.down(" Thanks for posting! ", state: Custom.complete)
                                                                            postButton.isEnabled = true
                                                                            
                                                                            //Refresh our Data after we add a new post.
                                                                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "addPostAfterPosting"), object: nil, userInfo: ["postId": post.objectId! as String])
                                                                            
                                                                            self.dismissViewController()
                                                                        }
                                                                            
                                                                        else if let error = error{
                                                                            
                                                                            /**
                                                                             * There was an error while saving the comment.
                                                                             * We now need to alert the user, delete the post we just created (in the background),
                                                                             * and allow the user to post again.
                                                                             */
                                                                            print(error)
                                                                            
                                                                            Drop.down(" There was an error with your Post. Try again. ", state: Custom.error)
                                                                            self.deletePost(post: post)
                                                                            postButton.isEnabled = true
                                                                            
                                                                            
                                                                        }else{
                                                                            
                                                                            /**
                                                                             * There was an error while saving the comment.
                                                                             * We now need to alert the user, delete the post we just created (in the background),
                                                                             * and allow the user to post again.
                                                                             */
                                                                            
                                                                            Drop.down(" There was an error with your Post. Try again. ", state: Custom.error)
                                                                            self.deletePost(post: post)
                                                                            postButton.isEnabled = true
                                                                            
                                                                        }
                                                                    })
                                                                    
                                                                }else if let error = error{
                                                                    
                                                                    /**
                                                                     * There was an error while saving the post.
                                                                     * We now need to alert the user
                                                                     * and allow the user to post again.
                                                                     */
                                                                    print(error)
                                                                    
                                                                    Drop.down(" There was an error with your Post. Try again. ", state: Custom.error)
                                                                    postButton.isEnabled = true
                                                                    
                                                                }else{
                                                                    
                                                                    /**
                                                                     * There was an error while saving the post.
                                                                     * We now need to alert the user
                                                                     * and allow the user to post again.
                                                                     */
                                                                    
                                                                    Drop.down(" There was an error with your Post. Try again. ", state: Custom.error)
                                                                    postButton.isEnabled = true
                                                                    
                                                                }
                                                            })
                                                        }
  
                                                    }
                                                }
                                            })
                                        }
                                      }))
                
            }else{ //COMMENT CONTAINS INVALID CHARACTERS
                
                let alertView = SCLAlertView()
                
                alertView.showTitle("Hey!", subTitle: "\n Please don't use any profanity. \n", style: .info, closeButtonTitle: "Okay", duration: 0.0, colorStyle: UIColor.purple.hex.flat, colorTextButton: 0xECF0F1, circleIconImage: UIImage(named: "alertPinIcon"), animationStyle: .leftToRight)
        
            }
            
        }else{ //EMPTY COMMENT
            
            let alertView = SCLAlertView()
            
            alertView.showTitle("Uh oh!", subTitle: "\n You can't post with an empty comment! \n", style: .info, closeButtonTitle: "Okay", duration: 0.0, colorStyle: UIColor.purple.hex.flat, colorTextButton: 0xECF0F1, circleIconImage: UIImage(named: "alertPinIcon"), animationStyle: .leftToRight)
        }
    }
    
    func deletePost(post: Post){
        post.deleteInBackground()
    }

    

    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = indexPath.section
        
        switch section{
            
        case 0:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "postMediaViewCell") as! PostMediaViewCell
            
            let postImageView = UIImageView(image: postImage)
            
            
            
            if (hasTakenVideo == true){

                let videoURL = selectedMovieURL
                self.player = AVPlayer(url: videoURL!)
                self.playerLayer = AVPlayerLayer(player: player)

                
                playerLayer.masksToBounds = true
                player.allowsExternalPlayback = true
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill

                cell.layer.addSublayer(playerLayer)
                playerLayer.frame = cell.mediaView.bounds

                return cell

            }else {
                postImageView.frame = cell.mediaView.bounds
                cell.mediaView.addSubview(postImageView)
                
                return cell
                
            }
            
        case 1:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "placesCell") as! PlacesCell
            
            cell.placesCollectionView.register(UINib(nibName: "PlaceImageCell", bundle: nil), forCellWithReuseIdentifier: "cell")
            cell.placesCollectionView.delegate = self
            cell.placesCollectionView.dataSource = self
            
            let collectionViewLayout = UICollectionViewFlowLayout()
            collectionViewLayout.scrollDirection = .horizontal
            cell.placesCollectionView.collectionViewLayout = collectionViewLayout
            cell.placesCollectionView.reloadData()
            
            return cell
            
        case 2:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "postCommentCell") as! PostCommentCell
            cell.commentTextField.delegate = self
            cell.commentTextField.addTarget(self, action: #selector(commentWasChanged), for: .editingChanged)
            cell.commentTextField.autocapitalizationType = .sentences
            
            return cell
            
        case 3:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "postButtonCell") as! PostButtonCell
            cell.postButton.contentMode = .scaleAspectFit
            cell.backgroundColor = lightGreen

            
            if let profilePictureUrl = ChoozyUser.current()?.profilePictureUrl{
                cell.postAuthorImageView.af_setImage(withURL: URL(string: profilePictureUrl)!, placeholderImage: UIImage(named: "person"), filter: AspectScaledToFillSizeCircleFilter(size: cell.postAuthorImageView.frame.size), imageTransition: .crossDissolve(0.1))
            }
            
            if let firstName = ChoozyUser.current()?.firstName{
                cell.postButton.setTitle("Post as " + firstName , for: .normal)
                cell.postButton.addTarget(self, action: #selector(createPost(_:)), for: .touchUpInside)
            }
            
            return cell
            
        default:
            
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
            cell.backgroundColor = black


            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let section = indexPath.section
        
        switch section{
        case 0:
            return self.view.bounds.size.width
        case 1:
            return 120
        case 2:
            return 120
        case 3:
            return 80
        default:
            return 80
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
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
        return 4
    }

    
    //MARK: - Camera Capture Functions
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera){
            let picker = UIImagePickerController()
            picker.view.frame = self.view.bounds
            picker.delegate = self
            picker.sourceType = UIImagePickerControllerSourceType.camera
            picker.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
            picker.allowsEditing = true
            self.view.addSubview(picker.view)
            present(picker, animated: true, completion: nil)
        }
    }
    
    //JT added for thumbnails
    private func thumbnailForVideoAtURL(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let imgGen = AVAssetImageGenerator(asset:asset)
        
        var time = asset.duration
        time.value = min(time.value, 2)
        
        do {
            let imageRef = try imgGen.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: imageRef)
            
        } catch {
            print("Error with thumbnails")
            return nil
        }
        
    }
    //MARK: - UIImagePickerController Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        guard let mediaType = info[UIImagePickerControllerMediaType] as? String else{
            return
        }
        
        if mediaType.contains("movie"){
            
            if let movieURL = info["UIImagePickerControllerMediaURL"] as? URL{
                selectedMovieURL = movieURL
            }
            
            if let selectedMovie = selectedMovieURL{

                self.moviePlayerController = MPMoviePlayerController(contentURL: selectedMovie)
                
                //self.dismiss(animated: true, completion: {(complete) in
                picker.view.fadeOut()
                
                hasTakenVideo = true
               
                //Reload the Table View
                postTableView.reloadData()
                
                //Find Places
                if placePost == true {
                    loadCellForPlace()
                } else {
                    getSuggestedPlaces()
                }
                

            }

        } else {
            guard let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage else{
                        return
            }
            originalImage = editedImage
            postImage = editedImage
    
            picker.view.fadeOut()
    
            hasTakenPhoto = true
            
            //Reload the Table View
            postTableView.reloadData()

            //Find Places
            if placePost == true {
                loadCellForPlace()
            } else {
                getSuggestedPlaces()
            }
            
        }
        
// cameron og code
//        guard let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage else{
//            return
//        }
//        
//        originalImage = editedImage
//        postImage = editedImage
//        
//        picker.view.fadeOut()
//        
//        hasTakenPhoto = true
//        
//        //Reload the Table View
//        postTableView.reloadData()
//        
//        //Find Places
//        getSuggestedPlaces()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Collection View Delegate & DataSource
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PlaceImageCell
        let place = suggestedPlaces[indexPath.row]
        cell.placeImageView.image = place.image
        cell.placeLabel.text = place.name
        print(place.name)
        
        cell.selectedBackgroundView = UIView(frame: cell.bounds)
        cell.selectedBackgroundView!.backgroundColor = lightGreen
        return cell
    }
    
    var selectedPlace = Place()
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let place = suggestedPlaces[indexPath.row]
        selectedPlace = place
        getPlaceSpecs()

        print("did select a place")
        print(selectedPlace)

    }
    
//    func placeHasChanged(sender: IndexPath){
//        
//        guard let content = sender.index(of: indexPath) else{
//            return
//        }
//        
//        selectedPlace = content
//    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return suggestedPlaces.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 120)
    }
    
    //Line Spacing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        //JT changed to 5
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    //MARK: - Text Field Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func keyboardWillShow(_ notification: NSNotification) {
        let userInfo = notification.userInfo!
        let keyboardHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
        postTableView.setContentOffset(CGPoint(x: 0, y: keyboardHeight), animated: false)
    }
    
    func keyboardWillHide(_ notification: NSNotification) {
        postTableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }
    
    //MARK: - Gesture Recognizer Delegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    var suggestedPlaces = [Place]()
    func getSuggestedPlaces(){
        
        let placesClient = GMSPlacesClient()
        
        placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }
            
            if let placeLikelihoodList = placeLikelihoodList {
                for likelihood in placeLikelihoodList.likelihoods {

                    let id = likelihood.place.placeID
                    let name = likelihood.place.name
                    let address = likelihood.place.formattedAddress
                    let likelihood = likelihood.likelihood
                    
                    let place = Place()
                    place.id = id
                    place.name = name
                    place.address = address
                    place.likelihood = likelihood
                    
                    self.loadPhotoForPlace(with: place.id!, completion: {(photo) in
                        place.image = photo
                        self.suggestedPlaces.append(place)
                        self.postTableView.reloadData()
                    })
                }
            }
        })
    }
    func loadCellForPlace(){
        let placesCliet = GMSPlacesClient()
        placesCliet.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            let place = Place()
            place.id = specPlace?.0
            place.name = specPlace?.1
            
            print(place.id)
            print(place.name)
            
            self.loadPhotoForPlace(with: place.id!, completion: {(photo) in
                place.image = photo
                self.suggestedPlaces.append(place)
                self.postTableView.reloadData()
            })
        })
    }
    
    func loadPhotoForPlace(with id: String, completion: @escaping (UIImage) -> ()){
        GMSPlacesClient.shared().lookUpPhotos(forPlaceID: id) { (photos, error) -> Void in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else {
                if let firstPhoto = photos?.results.first {
                    GMSPlacesClient.shared().loadPlacePhoto(firstPhoto, callback: { (photo, error) -> Void in
                        if let error = error {
                            print("Error: \(error.localizedDescription)")
                        } else {
                            completion(photo!)
                        }
                    })
                }
            }
        }
    }
    
    //MARK: - ScrollView Delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let offset = scrollView.contentOffset.y
        
        if offset < 0.0{
            
            let alpha = -offset / 80
            let scale = 1 + (-offset / 300)
            
            if offset <= -120{
                self.dismissViewController()
            }
        }
    }
    
    func commentWasChanged(sender: UITextField){
        
        guard let content = sender.text else{
            return
        }
        
        commentContent = content
    }

    //MARK: - Status Bar Methods
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
//    func getPlaceCord() {
//        let geoCoder = CLGeocoder()
//        print(self.selectedPlace.address!)
//        geoCoder.geocodeAddressString(self.selectedPlace.address!) {
//            (placemarks, error) in
//            let placemark = placemarks?.first
//            let lat = placemark?.location?.coordinate.latitude
//            let lon = placemark?.location?.coordinate.longitude
//            print(lat)
//            print(lon)
//            self.placeLat = lat!
//            self.placeLog = lon!
//        }
//    }
    func getPlaceSpecs() {
        let placesClient = GMSPlacesClient()
        let placeID = self.selectedPlace.id
        print(placeID)
        
        placesClient.lookUpPlaceID(placeID!, callback: { (place, err) -> Void in
            if let error = err {
                print("shit is fucked \(error.localizedDescription)")
                return
            }
            if let place = place {
                self.placeLat = place.coordinate.latitude
                print(self.placeLat)
                self.placeLog = place.coordinate.longitude
                print(self.placeLat)
                print("it worked")
            } else {
                print("no place details for \(placeID)")
            }
        })
    }
}
