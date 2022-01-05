//
//  Ringtone.swift
//  SimpleWebRTC
//
//  Created by sudayn on 6/2/21.
//  Copyright © 2021 n0. All rights reserved.
//

import Foundation
import AVKit

class Ringtone: NSObject {
    
    var player: AVAudioPlayer!
    
    override init() {
        super.init()
        let path = Bundle.main.path(forResource: "Captian", ofType: "mp3")
        player = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: path!))
        self.enableLoudSpeaker()
    }
    
    func play() {
        do {
            player.prepareToPlay()
//            player.volume = 1.0
            player.play()
        } catch let error as NSError {
            //self.player = nil
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
        
    }
    
    func enableLoudSpeaker() {
        let session = AVAudioSession.sharedInstance()
        var _: Error?
        try? session.setCategory(AVAudioSession.Category.playAndRecord)
        try? session.setMode(AVAudioSession.Mode.videoChat)
        try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        try? session.setActive(true)
    }
    
    func stop() {
        player.stop()
    }
}
