//
//  Communication.swift
//  SimpleWebRTC
//
//  Created by sudayn on 5/27/21.
//  Copyright © 2021 n0. All rights reserved.
//

import Foundation
import Firebase

struct ChatChannel {
    var caller: String
    var peer: String
}

struct JSON {
    static let encoder = JSONEncoder()
}

extension Encodable {
    subscript(key: String) -> Any? {
        return dictionary[key]
    }
    var dictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSON.encoder.encode(self))) as? [String: Any] ?? [:]
    }
    
    var toJson: String {
        if let s = try? JSONEncoder().encode(self) {
            return String(data: s, encoding: .utf8) ?? ""
        } else {
            return ""
        }
    }
}


struct Candidate: Codable {
    let sdp: String
    let sdpMLineIndex: Int32
    let sdpMid: String
    let serverUrl: String
}

struct SignalMessage: Codable {
    let type: String
    let sdp: String
    let candidate: Candidate?
    let command: String
    let initiator: Bool
    let sender: String
    let roomId: String
}

protocol OnPeerEvents {
    func onPeerJoined(userId: String)
    func onOfferReceived(sdp: String)
    func onAnswerReceived(sdp: String)
    func onCandidateReceived(candidate: Candidate)
    func onDisconnnect(userId: String)
}

class Communication {
    
    var roomsRef: DatabaseReference!
    var chatChannel: ChatChannel!
    var delegate: OnPeerEvents?
    var handler: DatabaseHandle!
    let asyncthread = DispatchQueue.global()
    
    init(chatChannel: ChatChannel) {
        self.chatChannel = chatChannel
        roomsRef = Database.database().reference(withPath: "rooms")
    }
    
    public func createRoom(roomId: String) {
        roomsRef.removeValue(completionBlock: {(err, ref) in
            guard err == nil else {
                return
            }
            
            self.roomsRef.child(roomId).child("initiator").setValue(self.chatChannel.caller, withCompletionBlock: {(err, ref) in
                guard err == nil else {
                    print(err)
                    return
                }
                
                self.startCall(roomId: roomId, initiator: true)
            })
        })
        
    }
    
    public func stopCall(roomId: String) {
        sendConfiguration(message: SignalMessage(type: "", sdp: "", candidate: nil, command: "disconnect", initiator: false, sender: chatChannel.caller, roomId: roomId))
    }
    
    public func startCall(roomId: String, initiator: Bool) {
        if handler != nil {
            roomsRef.child(roomId).child("peers").child(chatChannel.caller).removeObserver(withHandle: handler)
        }
        let message = SignalMessage(type: "", sdp: "", candidate: nil, command: "start", initiator: initiator, sender: chatChannel.caller, roomId: roomId)
        let r = roomsRef.child(roomId).child("peers").child(chatChannel.caller)
        let idRef = r.childByAutoId()
        idRef.setValue(message.toJson, withCompletionBlock: {(err, ref) in
            guard err == nil else {
                print(err)
                return
            }
            if !initiator {
                self.joinRoom(roomId: roomId, initiator: initiator)
            }
        })
        
        
        handler =  roomsRef.child(roomId).child("peers").child(chatChannel.caller).observe(.childAdded, with: {snapshot in
            let str = snapshot.value as! String
            print("\(self.chatChannel.caller) + " + str)
            if let j = try? JSONDecoder().decode(SignalMessage.self, from: str.data(using: .utf8)!) {
                switch j.command {
                case "join":
//                    self.fetchPeer(roomId: roomId, sender: j.sender)
                    self.chatChannel.peer = j.sender
                    self.delegate?.onPeerJoined(userId: j.sender)
                case "takeConfiguration":
                    switch j.type {
                    case "offer":
                        self.delegate?.onOfferReceived(sdp: j.sdp)
                    case "answer":
                        self.delegate?.onAnswerReceived(sdp: j.sdp)
                    case "candidate":
                        if let a = j.candidate {
                            self.delegate?.onCandidateReceived(candidate: a)
                        }
                        
                    default:
                        break
                    }
                case "disconnect":
                    self.delegate?.onDisconnnect(userId: j.sender)
                default:
                    break
                }
            }
        })
        
    }
    
    public func joinRoom(roomId: String, initiator: Bool) {
        let message = SignalMessage(type: "", sdp: "", candidate: nil, command: "join", initiator: initiator, sender: chatChannel.caller, roomId: roomId)
        let val = self.roomsRef.child(roomId).child("initiator").observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let item = snapshot.value as? String{
                self.chatChannel.peer = item
                let r = self.roomsRef.child(roomId).child("peers").child(item)
                let idRef = r.childByAutoId()
                idRef.setValue(message.toJson)
            }
        })

    }
    
    
    public func sendConfiguration(message: SignalMessage) {
        print(message)
        print(chatChannel.peer)
        let r = self.roomsRef.child(message.roomId).child("peers").child(chatChannel.peer)
        let idRef = r.childByAutoId()
        idRef.setValue(message.toJson)
    }
}
