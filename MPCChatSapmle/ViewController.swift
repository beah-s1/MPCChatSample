//
//  ViewController.swift
//  MPCChatSapmle
//
//  Created by Kentaro Abe on 2021/06/27.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        self.devices.append(peerID)
    }
    
    var peerId: MCPeerID?
    var session: MCSession?
    var peerBrowser: MCNearbyServiceBrowser?
    
    var devices = [MCPeerID]()
    @IBOutlet weak var identifierTextField: UITextField!
    @IBOutlet weak var chatBodyField: UITextField!
    
    @IBOutlet weak var tableView: UITableView!
    
    var chatHistory = [ChatHistory]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }

    @IBAction func identifierApply(_ sender: Any) {
        self.peerId = MCPeerID(displayName: identifierTextField.text ?? "")
        self.session = .init(peer: peerId!, securityIdentity: nil, encryptionPreference: .none)
        
        self.session?.delegate = self
        
        self.peerBrowser = MCNearbyServiceBrowser(peer: self.peerId!, serviceType: "serviceType")
        self.peerBrowser!.delegate = self
        
        self.present(MCBrowserViewController(browser: self.peerBrowser!, session: self.session!), animated: true)
        // encryptionPreferenceをrequiredにすると通信が暗号化されるらしい
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state{
        case .connected:
            devices.append(peerID)
        case .notConnected:
            devices = devices.filter{ $0 != peerID }
        default: break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // 相手からデータを受け取ったときの動き
        guard let stringData = String(data: data, encoding: .utf8) else{
            return
        }
        
        chatHistory.append(.init(peerId: peerID, body: stringData, date: Date()))
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // 実装必須らしいが何をするかわからない
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // 実装必須らしいが何をするかわからない
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatHistory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = chatHistory[indexPath.row].body
        
        return cell
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        self.devices.append(peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        self.devices = self.devices.filter { $0 != peerID }
    }
    
    @IBAction func send(_ sender: Any) {
        // チャット送信用
        try! session?.send(chatBodyField.text!.data(using: .utf8)!, toPeers: devices, with: .reliable)
    }
}

struct ChatHistory {
    let peerId: MCPeerID
    let body: String
    let date: Date
}
