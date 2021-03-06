//
//  Question.swift
//  Rumpel
//
//  Created by Harel Avikasis on 25/06/2017.
//  Copyright © 2017 HarelAvikasis. All rights reserved.
//

import Foundation

class Question
{
    var id : String = ""
    var questionText = ""
    var senderId = ""
    var answers = [Answer]()
    var initialTime : Int = 0
    var timeToAnswer : Int = 0
    var answer : Answer?
    var isRightAnswer = false
    var isQuestionOpen = true
    
    init(question:[String:Any])
    {
        self.id = question["id"] as? String ?? ""
        self.questionText = question["questionText"] as? String ?? ""
        self.senderId = question["senderId"] as? String ?? ""
        self.timeToAnswer = question["timeToAnswer"] as? Int ?? 0
        self.initialTime = question["initialTime"] as? Int ?? 0
        self.isQuestionOpen = question["questionOpen"] as? Bool ?? false
        self.isRightAnswer = question["isRightAnswer"] as? Bool ?? false
        
        if let answers = question["answers"] as? [[String:Any]]
        {
            answers.forEach({ (answer) in
                self.answers.append(Answer(answer: answer))
            })
        }
        
        if let answer = question["answer"] as? [String:Any]
        {
            self.answer = Answer(answer: answer)
            
            if self.answer?.answerText == ""
            {
                self.answer = getRightAnswer()
            }
        }
    }
    init(){}
    
    func getObjectAsDictionary()->[String: Any]
    {
        
        var returnDict = ["id": self.id,
                "questionText":self.questionText,
                "senderId":self.senderId,
                "timeToAnswer":self.timeToAnswer,
                "initialTime":self.initialTime,
                "questionOpen":self.isQuestionOpen,
                "isRightAnswer" : self.isRightAnswer,
                "answer" : self.answer != nil ? self.answer!.getObjectAsDictionary() : Answer(answerText: "", isRight: false).getObjectAsDictionary() ] as [String : Any]
        
        var answerDict =  [String: Any]()
        for (index,answer) in answers.enumerated()
        {
            answerDict["\(index)"] = answer.getObjectAsDictionary()
        }
        returnDict["answers"] = answerDict
        return returnDict
    }
    
    func closeQuestion()
    {
        let now = Date().timeIntervalSince1970
        self.timeToAnswer = Int(now - TimeInterval(initialTime))
        isQuestionOpen = false
    }
    
    func checkAnswer(withAnswerIndex index: Int)->Bool
    {
        closeQuestion()
        self.answer = answers[index]
        if(answers[index].isRight)
        {
            isRightAnswer = true
            return true
        }
        else
        {
            return false
        }
    }
    
    func getMessageTextForQuestion()->String
    {
        var returnStr = "\(self.questionText)"
        if self.isQuestionOpen
        {
            returnStr += "\n"
            returnStr += "1.\(answers[0].answerText)\n"
            returnStr += "2.\(answers[1].answerText)\n"
            returnStr += "3.\(answers[2].answerText)\n"
            returnStr += "4.\(answers[3].answerText)\n"
            return returnStr
        }
        else
        {
            let firstLetter = "\(self.questionText.characters.first!)"
            if firstLetter.language() == "he"
            {
                if senderId == UserManager.manager.userId!
                {
                    returnStr += self.isRightAnswer ? "✅" : "❌"

                }
                else
                {
                    var str = self.isRightAnswer ? "✅" : "❌"
                    str += returnStr
                    returnStr = str
                }
            }
            else
            {
                if senderId == UserManager.manager.userId
                {
                    var str = self.isRightAnswer ? "✅" : "❌"
                    str += returnStr
                    returnStr = str
                }
                else
                {
                    returnStr += self.isRightAnswer ? "✅" : "❌"
                }
            }
            returnStr += "\n  --\(answer != nil ? answer!.answerText :  getRightAnswer()!.answerText)--"
            return returnStr
        }
    }
    func getRightAnswer()->Answer?
    {
        var retAnswer : Answer? = nil
        answers.forEach { (answer) in
            if answer.isRight
            {
                retAnswer = answer
            }
        }
        return retAnswer
    }
}
