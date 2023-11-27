# KYNearbyService

A service for nearby discovery and communication.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue?style=flat) ![iOS](https://img.shields.io/badge/iOS-15.5%2B-blue?style=flat)
![SwiftPM](https://img.shields.io/badge/SwiftPM-ready-green)

<div align="center">
<img src="https://raw.githubusercontent.com/Kjuly/preview/main/KYNearbyService/01.png" alt="iPhone Preview" height="360" /> 
<img src="https://raw.githubusercontent.com/Kjuly/preview/main/KYNearbyService/Mac_01.png" alt="Mac Preview" height="360" />
</div>

## Usage

1. Setup KYNearbyService with your service type.

```Swift
KYNearbyService.setup(with: KYNearbyServiceConfiguration(serviceType: "your-service")
```

> [!IMPORTANT]
> Make sure you've provided [NSBonjourServices](https://developer.apple.com/documentation/bundleresources/information_property_list/nsbonjourservices) in your *.plist file.
> 
> ```xml
> <key>NSBonjourServices</key>
> <array>
>   <string>_your-service._tcp</string>
>   <string>_your-service._udp</string>
> </array>
> ```

2. Use the existing `KYNearbyConnectionView` or setup your own one to provide as the connection view. A demo project is available under "[/KYNearbyServiceDemo](KYNearbyServiceDemo)".

3. Observe notifications (`Notification.Name.KYNearbyService.*`) to handle events.

| Notification | When | Notes
| --- | --- | ---
| didUpdatePeerDisplayName | The user changed the display name | The name is provided as `note.object`.
| shouldSendResource      | The user pressed the "SEND" button | The target peer item (KYNearbyPeerModel instance) is provided as `note.object`. And you can use `KYNearbyService.sendResource(for:at:withName:completion:)` to send the resource to the target peer.
| didStartReceivingResource | The service start receiving resource |
| didReceiveResource | The service did receive resource | The details are available in `note.userInfo`. And the file will be saved to `KYNearbyServiceDefaultFolderURL.archives` by default. You can config the destination folder url by `KYNearbyServiceConfiguration`.

e.g.

```Swift
NotificationCenter.default.addObserver(
  self,
  selector: #selector(_handleKYNearbyServiceShouldSendResourceNotification),
  name: .KYNearbyService.shouldSendResource,
  object: nil)
```
