//
//  VideoCallViewController.swift
//  SimpleWebRTC
//
//  Created by sudayn on 5/29/21.
//  Copyright © 2021 n0. All rights reserved.
//

import UIKit
import WebRTC
import Firebase
import VideoToolbox

enum CallType {
    case Join
    case Create
}

class VideoCallViewController: UIViewController {
    
    @IBOutlet weak var clientViewRenderer: UIView!
    @IBOutlet weak var localViewRenderer: UIView!
    var webRTCClient: WebRTCClient!
    var useCustomCapturer: Bool = false
    var cameraFilter: CameraFilter?
    var cameraSession: CameraSession?
    var chan: ChatChannel!
    var comm: Communication!
    var roomId: String = "room_xyz"
    var loudSpeaker = false
    var mute = false
    var enableVideo = true
    var type: CallType = .Create
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var imgView: UIImageView!
    var username: String = ""
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
//        useCustomCapturer = TARGET_OS_SIMULATOR == 0
//        initializeFirebase()
        enteredCall()
    }
    
    private func initializeFirebase() {
        let ref = Database.database().reference(withPath: "users").child(username).child("events").child("active_call")
        ref.removeValue()
        
        ref.observe(.childAdded, with: {snapshot in
            let str = snapshot.value as! String
            if let j = try? JSONDecoder().decode(SignalMessage.self, from: str.data(using: .utf8)!) {
                switch j.command {
                case "call":
                    self.setupCall()
                default:
                    break
                }
            }
        })
        
    }
    
    private func setupCall() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "IncomingCallViewController") as! IncomingCallViewController
        vc.modalPresentationStyle = .overCurrentContext
        vc.delegate = self
        self.navigationController?.present(vc, animated: true, completion: nil)
    }
    
    private func enteredCall() {
        initializeWebRTC()
        initializeCommunication()
        if type == .Create {
            comm.createRoom(roomId: roomId)
//            startCall()
        } else if type == .Join {
            comm.startCall(roomId: roomId, initiator: false)
        }
        
    }
    
    private func startCall() {
//        let users = Database.database().reference(withPath: "users")
//        print(users)
//        let ref = users.child(chan.peer).child("events").child("active_call")
//        ref.removeValue(completionBlock: {(err, r) in
//            let message = SignalMessage(type: "", sdp: "", candidate: nil, command: "call", initiator: false, sender: self.chan.caller, roomId: self.roomId)
//            let idRef = ref.childByAutoId()
//            idRef.setValue(message.toJson)
//        })
    }
    
    private func startOffer() {
        guard webRTCClient != nil else {
            print("webrtc is null in start offer")
            return
        }
        webRTCClient.connect(onSuccess: { (offerSDP: RTCSessionDescription) -> Void in
//            self.sendSDP(sessionDescription: offerSDP)
            self.comm.sendConfiguration(message: SignalMessage(type: "offer", sdp: offerSDP.sdp, candidate: nil, command: "takeConfiguration", initiator: true, sender: self.chan.caller, roomId: self.roomId))
        })
    }
    
    
    @IBAction func onVideo(_ sender: Any) {
        enableVideo = !enableVideo
        if enableVideo {
            videoButton.setImage(UIImage(named: "video"), for: .normal)
//            localViewRenderer.isHidden = false
        } else {
            videoButton.setImage(UIImage(named: "video_disabled"), for: .normal)
//            localViewRenderer.isHidden = true
        }
        webRTCClient.enableVideo(enable: enableVideo)
    }
    
    private func initializeCommunication() {
        chan = ChatChannel(caller: username, peer: "")
        comm = Communication(chatChannel: chan)
        comm.delegate = self
    }
    
    private func initializeWebRTC() {
        webRTCClient = WebRTCClient()
        if webRTCClient.isConnected {
            dismiss(animated: true, completion: nil)
            return
        }
        webRTCClient.delegate = self
        webRTCClient.setup(videoTrack: true, audioTrack: true, dataChannel: true, customFrameCapturer: useCustomCapturer)
        
        if useCustomCapturer && TARGET_OS_SIMULATOR == 0 {
            print("--- use custom capturer ---")
            self.cameraSession = CameraSession()
            self.cameraSession?.delegate = self
            self.cameraSession?.setupSession()
            self.cameraFilter = CameraFilter()
        }
        webRTCClient.setupLocalViewFrame(frame: self.localViewRenderer.bounds)
        webRTCClient.setupRemoteViewFrame(frame: self.clientViewRenderer.bounds)
        
        let remoteView = webRTCClient.remoteVideoView()
        remoteView.translatesAutoresizingMaskIntoConstraints = false
        remoteView.frame = self.clientViewRenderer.bounds
        self.clientViewRenderer.addSubview(remoteView)
        remoteView.leadingAnchor.constraint(equalTo: self.clientViewRenderer.leadingAnchor).isActive = true
        remoteView.trailingAnchor.constraint(equalTo: self.clientViewRenderer.trailingAnchor).isActive = true
        remoteView.bottomAnchor.constraint(equalTo: self.clientViewRenderer.bottomAnchor).isActive = true
        remoteView.topAnchor.constraint(equalTo: self.clientViewRenderer.topAnchor).isActive = true
        //
        let localView = webRTCClient.localVideoView()
        localView.translatesAutoresizingMaskIntoConstraints = false
        self.localViewRenderer.addSubview(localView)
        localView.leadingAnchor.constraint(equalTo: self.localViewRenderer.leadingAnchor).isActive = true
        localView.trailingAnchor.constraint(equalTo: self.localViewRenderer.trailingAnchor).isActive = true
        localView.bottomAnchor.constraint(equalTo: self.localViewRenderer.bottomAnchor).isActive = true
        localView.topAnchor.constraint(equalTo: self.localViewRenderer.topAnchor).isActive = true
    }
    
    @IBAction func onCameraSwitched(_ sender: Any) {
        webRTCClient.switchCameraPosition()
    }
    
    @IBAction func onDismiss(_ sender: Any) {
        if webRTCClient.isConnected {
            comm.stopCall(roomId: self.roomId)
            webRTCClient.disconnect()
        } else {
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    
    @IBAction func toggleSpeaker(_ sender: Any) {
        loudSpeaker = !loudSpeaker
        webRTCClient.setSpeakerStates(enabled: loudSpeaker)
    }
    
    @IBAction func onMute(_ sender: Any) {
        mute = !mute
        if !mute {
            micButton.setImage(UIImage(named: "audio"), for: .normal)
        } else {
            micButton.setImage(UIImage(named: "audio_disabled"), for: .normal)
        }
        webRTCClient.enableAudio(enable: !mute)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.webRTCClient = nil
    }
}

extension VideoCallViewController: WebRTCClientDelegate {
    func didGenerateCandidate(iceCandidate: RTCIceCandidate) {
        comm.sendConfiguration(message: SignalMessage(type: "candidate", sdp: "", candidate: Candidate(sdp: iceCandidate.sdp, sdpMLineIndex: iceCandidate.sdpMLineIndex, sdpMid: iceCandidate.sdpMid ?? "", serverUrl: iceCandidate.serverUrl ?? ""), command: "takeConfiguration", initiator: false, sender: self.chan.caller, roomId: self.roomId))
    }
    
    func didIceConnectionStateChanged(iceConnectionState: RTCIceConnectionState) {
        var state = ""
        switch iceConnectionState {
        case .checking:
            state = "checking..."
        case .closed:
            state = "closed"
        case .completed:
            state = "completed"
        case .connected:
            state = "connected"
        case .count:
            state = "count..."
        case .disconnected:
            state = "disconnected"
        case .failed:
            state = "failed"
        case .new:
            state = "new..."
        }
        print(state)
//        self.webRTCStatusLabel.text = self.webRTCStatusMesasgeBase + state
    }
    
    func didOpenDataChannel() {
        
    }
    
    func didReceiveData(data: Data) {

    }
    
    func didReceiveMessage(message: String) {
        print("received message")
        print(message)
    }
    
    func didConnectWebRTC() {
        print("did connect webrtc")
    }
    
    func didDisconnectWebRTC() {
        self.webRTCClient.delegate = nil
        self.dismiss(animated: true, completion: nil)
    }
    
    
}

extension VideoCallViewController: CameraSessionDelegate {
    func didOutput(_ sampleBuffer: CMSampleBuffer) {
        if self.useCustomCapturer {
         
            
            if let cvpixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
//                let ciimage : CIImage = CIImage(cvPixelBuffer: cvpixelBuffer).oriented(.right)
//                let image = convert(cmage: ciimage)
//                print("sending data")
//                webRTCClient.sendData(data: image.jpegData(compressionQuality: 0.9)!.base64EncodedData())
                
                if let buffer = self.cameraFilter?.apply(cvpixelBuffer){
                    self.webRTCClient.captureCurrentFrame(sampleBuffer: buffer)
                }else{
                    print("no applied image")
                }
            }else{
                print("no pixelbuffer")
            }
            //            self.webRTCClient.captureCurrentFrame(sampleBuffer: buffer)
        }
    }
    
    func convert(cmage: CIImage) -> UIImage {
         let context = CIContext(options: nil)
         let cgImage = context.createCGImage(cmage, from: cmage.extent)!
         let image = UIImage(cgImage: cgImage)
         return image
    }
    
    func getDataFromCMSampleBuffer (sampleBuffer: CMSampleBuffer) -> Data? {
        if CMSampleBufferDataIsReady (sampleBuffer),
           let pixelBuffer = CMSampleBufferGetImageBuffer (sampleBuffer) {
            let ciImage = CIImage (cvImageBuffer: pixelBuffer)
            let image = UIImage (ciImage: ciImage)
            return (image.jpegData (compressionQuality: 0.0)) // Error Thread 7: EXC_RESOURCE RESOURCE_TYPE_MEMORY (limit = 50 MB, unused = 0x0)
        }
        return nil
    }
    
}

extension VideoCallViewController: OnPeerEvents {
    func onDisconnnect(userId: String) {
//        if webRTCClient.isConnected {
//            webRTCClient.disconnect()
//        } else {
//            self.dismiss(animated: true, completion: nil)
//        }
        
    }
    
    func onPeerJoined(userId: String) {
        startOffer()
    }
    
    func onOfferReceived(sdp: String) {
        guard webRTCClient != nil else {
            print("webrtc is null in offer received")
            return
        }
        webRTCClient.receiveOffer(offerSDP: RTCSessionDescription(type: .offer, sdp: sdp), onCreateAnswer: {sdp in
            self.comm.sendConfiguration(message: SignalMessage(type: "answer", sdp: sdp.sdp, candidate: nil, command: "takeConfiguration", initiator: false, sender: self.chan.caller, roomId: self.roomId))
        })
    }
    
    func onAnswerReceived(sdp: String) {
        guard webRTCClient != nil else {
            print("webrtc is null in answer received")
            return
        }
        webRTCClient.receiveAnswer(answerSDP: RTCSessionDescription(type: .answer, sdp: sdp))
    }
    
    func onCandidateReceived(candidate: Candidate) {
        guard webRTCClient != nil else {
            print("webrtc is null in candidate received")
            return
        }
        let c = RTCIceCandidate(sdp: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid)
        self.webRTCClient.receiveCandidate(candidate: c)
    }
    
    
}

extension UIImage {
    public convenience init?(pixelBuffer: CVPixelBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)

        guard let c = cgImage else {
            return nil
        }

        self.init(cgImage: c)
    }
}

extension VideoCallViewController: IncomingCallDelegate {
    func onAccept() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoCallViewController") as! VideoCallViewController
        vc.type = .Join
        vc.modalPresentationStyle = .overCurrentContext
        self.navigationController?.present(vc, animated: true, completion: nil)
    }
    
    func onDecline() {
        
    }
}
