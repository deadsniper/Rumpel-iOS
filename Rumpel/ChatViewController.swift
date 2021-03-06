//
//  ChatViewController.swift
//  Rumpel
//
//  Created by Harel Avikasis on 29/06/2017.
//  Copyright © 2017 HarelAvikasis. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import AlamofireImage

public enum Setting: String{
    case removeBubbleTails = "Remove message bubble tails"
    case removeSenderDisplayName = "Remove sender Display Name"
    case removeAvatar = "Remove Avatars"
}

let buttonsHeight : CGFloat = 40
let buttonsWidth : CGFloat = (UIScreen.main.bounds.width / 2) - 2

class ChatViewController: JSQMessagesViewController,AddNewQuestionProtocol {

    
    var answersView: UIView = UIView(frame: CGRect(x: 0, y: UIScreen.main.bounds.height - 134, width: UIScreen.main.bounds.width, height: 134))
    var questionLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 54))
    var answerOneButton: UIButton = UIButton(frame: CGRect(x: 1, y: 134 - (buttonsHeight * 2), width:  buttonsWidth, height: buttonsHeight))
    var answerTwoButton: UIButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width / 2 , y: 134 - (buttonsHeight * 2), width:  buttonsWidth, height: buttonsHeight))
    var answerThreeButton: UIButton = UIButton(frame: CGRect(x: 1, y: 134 - buttonsHeight, width:  buttonsWidth, height: buttonsHeight))
    var answerFourButton: UIButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width / 2, y: 134 - buttonsHeight, width:  buttonsWidth, height: buttonsHeight))
    var answerBackgorund1 = UIView()
    var answerBackgorund2 = UIView()
    var answerBackgorund3 = UIView()
    var answerBackgorund4 = UIView()
    var questionBackgorund = UIView()
    
    var addAnswerButton: UIButton = UIButton(frame: CGRect(x: 25, y: UIScreen.main.bounds.height - 75, width:  50, height: 50))

    let theStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    var addQuestionVC : NewQuestionViewController!
    var firstTime = true
    
    var chat : Chat?
    {
        didSet {
            if self.collectionView != nil
            {
                setOutlets()
                self.collectionView.reloadData()
            }
        }
    }
    var contact: Contact!
    var messages = [JSQMessage]()
    let defaults = UserDefaults.standard
    var incomingBubble: JSQMessagesBubbleImage!
    var outgoingBubble: JSQMessagesBubbleImage!
    var userImage = UIImageView()
    var contactImage = UIImageView()
    
//  MARK: Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        self.collectionView.backgroundColor = UIColor.clear
        
        let imView = UIImageView(image: RumpelFileManager.manager.loadImgae() ?? #imageLiteral(resourceName: "defaultBackground"))
        imView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        imView.contentMode = .scaleAspectFill
        imView.clipsToBounds = true
        self.view.insertSubview(imView, at: 0)
        if let url = URL(string: contact.imageUrl) {
            UIImageView.setImage(imageView: contactImage, url: url, placeholder: nil)
        }
        if let url = URL(string: UserManager.manager.userPhotoUrl) {
            UIImageView.setImage(imageView: userImage, url: url, placeholder: nil)
        }
        
        addQuestionVC = self.theStoryboard.instantiateViewController(withIdentifier :"NewQuestionViewController") as! NewQuestionViewController
        addQuestionVC.modalPresentationStyle = .overFullScreen
        addQuestionVC.delegate = self
        self.title = "\(contact.name)"
        self.inputToolbar.isHidden = true
        self.senderId = UserManager.manager.userId
        self.senderDisplayName = UserManager.manager.name
        setOutlets()
        incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
        outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.lightGray)
        
        if defaults.bool(forKey: Setting.removeAvatar.rawValue) {
            collectionView?.collectionViewLayout.incomingAvatarViewSize = .zero
            collectionView?.collectionViewLayout.outgoingAvatarViewSize = .zero
        } else {
            collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault, height:kJSQMessagesCollectionViewAvatarSizeDefault )
            collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault, height:kJSQMessagesCollectionViewAvatarSizeDefault )
        }

        collectionView?.collectionViewLayout.springinessEnabled = false
        
        automaticallyScrollsToMostRecentMessage = true
        self.collectionView?.reloadData()
        self.collectionView?.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        FirebaseManager.manager.removeObsreves()
    }
    
//  MARK: Public Functions
    func setOutlets()
    {
        messages.removeAll()
        answersView.removeFromSuperview()
        addAnswerButton.removeFromSuperview()
        
        chat?.questions.forEach({ (question) in
            let message = JSQMessage(senderId: question.senderId, senderDisplayName: question.senderId == self.senderId ? self.senderDisplayName : contact.name, date: Date(timeIntervalSince1970: TimeInterval(question.initialTime)), text:  question.getMessageTextForQuestion())
            messages.append(message!)
        })
        
        if (chat?.isThereOpenQuestion)!
        {
            if (chat?.fetchOpenQuestoin()?.senderId != UserManager.manager.userId)
            {
                self.collectionView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 134, right: 0)
                self.view.addSubview(answersView)
                self.view.bringSubview(toFront: answersView)
                if (chat?.isThereOpenQuestion)!
                {
                    if chat?.fetchOpenQuestoin() != nil
                    {
                        self.setButtons(withQuestion: (chat?.fetchOpenQuestoin())!)
                    }
                }
            }
        }
        else
        {
            if !firstTime
            {
                self.collectionView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 10, right: 0)
            }
            

            setAddQuestionButton()
        }
        firstTime = false
    }
    
    func answerSelected(sender: UIButton!)
    {
        _ = chat?.fetchOpenQuestoin()?.checkAnswer(withAnswerIndex: sender.tag)
        messages.removeAll()
        chat?.questions.forEach({ (question) in
            messages.append(JSQMessage(senderId: question.senderId, senderDisplayName: question.senderId == self.senderId ? self.senderDisplayName : contact.name, date: Date(timeIntervalSince1970: TimeInterval(question.initialTime)), text:  question.getMessageTextForQuestion()))
        })
        chat?.isThereOpenQuestion = false
        self.updatChatInFirebase()
        setOutlets()
        self.collectionView?.reloadData()
        self.collectionView?.layoutIfNeeded()
        ContactsManager.manager.updateContactNewMessageById(id: self.contact.id, withBadge: false)
        UserDefaults.standard.removeObject(forKey: self.contact.id)
        self.contact.hasNewQuestion = false

    }
    
    func addQuestion(sender: UIButton!)
    {
        self.present(addQuestionVC, animated: true)
    }
    
    func updatChatInFirebase()
    {
        FirebaseManager.manager.updateChat(withChat: chat!)
    }
    
//  MARK: Add Question protocol Functions
    func addQuestionToConversation(question: Question)
    {
        self.chat?.questions.append(question)
        self.chat?.isThereOpenQuestion = true
        self.scrollToBottom(animated: true)
        FirebaseManager.manager.updateChat(withChat: chat!)
        FirebaseManager.manager.fetchContactToken(withContactId: self.contact.id) { (tokenId) in
            if let token = tokenId
            {
                let title = "\(UserManager.manager.name!) Asked"
                let pushPayload = NotificationPayload(title: title, userName: UserManager.manager.name!, body: "\(question.questionText)",data: UserManager.manager.facebookId ?? "")
                let pushObject = PushNotificaionObject(to: token, notificationPayload: pushPayload)
                PushNotificationsManager.manager.sendPush(to: pushObject, completion: { (bool) in
                    print("Push was success? \(bool)")
                })
                ContactsManager.manager.updateContactNewMessageById(id: self.contact.id, withBadge: false)
            }
            self.scrollToBottom(animated: true)
        }
    }
    
//MARK: JSQMessages CollectionView DataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageDataForItemAt indexPath: IndexPath) -> JSQMessageData {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageBubbleImageDataForItemAt indexPath: IndexPath) -> JSQMessageBubbleImageDataSource {
            return  messages[indexPath.item].senderId == self.senderId ? self.outgoingBubble : self.incomingBubble
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, avatarImageDataForItemAt indexPath: IndexPath) -> JSQMessageAvatarImageDataSource? {
        let message = messages[indexPath.item]
        let avatar = getAvatar(forSenderId: message.senderId)
        return avatar
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForCellTopLabelAt indexPath: IndexPath) -> NSAttributedString? {
        /**
         *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
         *  The other label text delegate methods should follow a similar pattern.
         *
         *  Show a timestamp for every 3rd message
         */
        if (indexPath.item % 3 == 0) {
            let message = messages[indexPath.item]
            let range = (JSQMessagesTimestampFormatter.shared().time(for: message.date) as NSString).range(of: JSQMessagesTimestampFormatter.shared().time(for: message.date))
            let str = NSMutableAttributedString(string: JSQMessagesTimestampFormatter.shared().time(for: message.date))
            str.addAttribute(NSForegroundColorAttributeName, value: UIColor.white , range: range)
            return str
        }
        
        return nil
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath) -> NSAttributedString? {
        let message = messages[indexPath.item]
        
        // Displaying names above messages
        //Mark: Removing Sender Display Name
        /**
         *  Example on showing or removing senderDisplayName based on user settings.
         *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
         */
//        if defaults.bool(forKey: Setting.removeSenderDisplayName.rawValue) {
//            return nil
//        }
//        
//        if message.senderId == self.senderId {
//            return NSAttributedString(string: senderDisplayName)
//        }
        
        return nil //NSAttributedString(string: message.senderDisplayName)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellTopLabelAt indexPath: IndexPath) -> CGFloat {
        /**
         *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
         */
        
        /**
         *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
         *  The other label height delegate methods should follow similarly
         *
         *  Show a timestamp for every 3rd message
         */
        if indexPath.item % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0.0
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForMessageBubbleTopLabelAt indexPath: IndexPath) -> CGFloat {
        
        /**
         *  Example on showing or removing senderDisplayName based on user settings.
         *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
         */
        if defaults.bool(forKey: Setting.removeSenderDisplayName.rawValue) {
            return 0.0
        }
        
        /**
         *  iOS7-style sender name labels
         */
        let currentMessage = self.messages[indexPath.item]
        
        if currentMessage.senderId == self.senderId {
            return 0.0
        }
        
        if indexPath.item - 1 > 0 {
            let previousMessage = self.messages[indexPath.item - 1]
            if previousMessage.senderId == currentMessage.senderId {
                return 0.0
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
//  MARK: Private Functions
    private func getUserInitials(withUserName name:String)->String
    {
        var nameArray = name.components(separatedBy: " ")
        if nameArray.count >= 2
        {
            let firstFromName = nameArray[0].substring(to:nameArray[0].index(nameArray[0].startIndex, offsetBy: 1)).uppercased()
            let firstFromLastName = nameArray[1].substring(to:nameArray[1].index(nameArray[1].startIndex, offsetBy: 1)).uppercased()
            return "\(firstFromName)\(firstFromLastName)"
        }
        else if nameArray.count != 0
        {
            return nameArray[0].substring(to:nameArray[0].index(nameArray[0].startIndex, offsetBy: 1)).uppercased()
        }
        return "NA"
    }
    
    private func getAvatar(forSenderId id: String) -> JSQMessagesAvatarImage?
    {
        if id != UserManager.manager.userId
        {
            if contact.imageUrl == "" || contactImage.image == nil
            {
                return JSQMessagesAvatarImageFactory.avatarImage(withUserInitials: self.getUserInitials(withUserName: self.contact.name), backgroundColor: UIColor.jsq_messageBubbleGreen(), textColor:  UIColor.white, font:  UIFont.systemFont(ofSize: 12), diameter: 25)
            }
            else
            {
                return JSQMessagesAvatarImageFactory.avatarImage(with: contactImage.image, diameter: 25)
            }
        }
        else
        {
            if (UserManager.manager.userPhotoUrl == "" || userImage.image == nil)
            {
                return JSQMessagesAvatarImageFactory.avatarImage(withUserInitials: self.getUserInitials(withUserName: UserManager.manager.name!), backgroundColor: UIColor.jsq_messageBubbleGreen(), textColor:  UIColor.white, font:  UIFont.systemFont(ofSize: 12), diameter: 25)
            }
            else
            {
                return JSQMessagesAvatarImageFactory.avatarImage(with: userImage.image, diameter: 25)
 
            }
        }
    }
   
}
