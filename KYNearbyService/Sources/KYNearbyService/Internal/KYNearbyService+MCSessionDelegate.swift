//
//  KYNearbyService+MCSessionDelegate.swift
//  KYNearbyService
//
//  Created by Kjuly on 8/2/2022.
//  Copyright © 2022 Kaijie Yu. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import KYLogger

extension KYNearbyService: MCSessionDelegate {

  // Remote peer changed state.
  public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    KYLog(.notice, "Peer \"\(peerID.displayName)\" did Change State: \(state)")
    guard let item = p_getItem(with: peerID) else {
      return
    }

    if item.isVisibleToOthers {
      DispatchQueue.main.async {
        item.updateState(with: state)
        NotificationCenter.default.post(name: .KYNearbyService.peerDidChangeState, object: item)
      }
    } else {
      // Rm invisible peer when disconnected it.
      if state == .notConnected {
        p_removePeerItem(item)
      }
    }
  }

  // Received data from remote peer.
  public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    do {
      let message = try JSONSerialization.jsonObject(with: data, options: [])
      if let decodedInfo = message as? [String: [String: Any]] {
        decodedInfo.forEach { (key: String, value: [String: Any]) in
          self.receivedResourceActionInfo[key] = value
        }
        KYLog(.notice, "Received decoded info: \(decodedInfo); Latest cached: \(self.receivedResourceActionInfo)")
      }
    } catch {
      KYLog(.error, error.localizedDescription)
    }
  }

  // Received a byte stream from remote peer.
  public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {

  }

  // Start receiving a resource from remote peer.
  public func session(
    _ session: MCSession,
    didStartReceivingResourceWithName resourceName: String,
    fromPeer peerID: MCPeerID,
    with progress: Progress
  ) {
    KYLog(.notice, "Did start receiving resource w/ name: \(resourceName)")
    guard let item = p_getItem(with: peerID) else {
      return
    }

    DispatchQueue.main.async {
      item.startProcessing(forReceiving: true)

      progress.kind = .file
      progress.fileOperationKind = .receiving
      item.progress = progress

      NotificationCenter.default.post(name: .KYNearbyService.didStartReceivingResource, object: item)
    }
  }

  // Finished receiving a resource from remote peer and saved the content
  // in a temporary location - the app is responsible for moving the file
  // to a permanent location within its sandbox.
  public func session(
    _ session: MCSession,
    didFinishReceivingResourceWithName resourceName: String,
    fromPeer peerID: MCPeerID,
    at localURL: URL?,
    withError error: Error?
  ) {
    KYLog(.notice, """
Did finish receiving resource
  - Name: \(resourceName)
  - URL: \(String(describing: localURL))
  - ERROR: \(String(describing: error))
""")

    var userInfo: [String: Any] = [KYNearbyServiceNotificationUserInfoKey.filename: resourceName]

    if let item = p_getItem(with: peerID) {
      DispatchQueue.main.async {
        item.doneProcessing(with: nil)
      }
      userInfo[KYNearbyServiceNotificationUserInfoKey.peerItem] = item
    }

    if let localURL {
      do {
        // Craete destination path to copy the received resource to.
        //
        // Note: `localURL` is a unique url generated by system,
        //   i.e., `localURL.lastPathComponent` won't get any meaningful name (it's sth like resource.K7FOZWtIaUdp7Gwb).
        //
        var destinationURL: URL

        // If resource action info has been provided, mv the file to "tmp" folder and leave it to user to handle manually.
        if let resourceActionInfo = p_popResourceActionInfo(with: resourceName) {
          userInfo[KYNearbyServiceNotificationUserInfoKey.extraActionInfo] = resourceActionInfo
          destinationURL = try KYNearbyService.tempFileURLForReceivedFile(with: resourceName)
        } else {
          destinationURL = try KYNearbyService.fileURLToArchiveReceivedFile(with: resourceName)
        }
        KYLog(.debug, "* destinationURL: \(destinationURL)")

        try FileManager.default.copyItem(at: localURL, to: destinationURL)
        userInfo[KYNearbyServiceNotificationUserInfoKey.url] = destinationURL

      } catch {
        KYLog(.error, "Failed to copy file, error: \(error.localizedDescription)\n* localURL: \(localURL)")
      }

    } else {
      KYLog(.warn, "The localURL is nil, do nothing.")
    }

    if userInfo.isEmpty {
      return
    }
    DispatchQueue.main.async {
      NotificationCenter.default.post(name: .KYNearbyService.didReceiveResource, object: nil, userInfo: userInfo)
    }
  }
}
