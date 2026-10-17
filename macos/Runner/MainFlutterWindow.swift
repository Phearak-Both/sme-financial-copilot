import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    // Demo only: a phone-sized window (about an iPhone 15 screen in points).
    let phoneSize = NSSize(width: 393, height: 852)
    self.setContentSize(phoneSize)
    self.contentMinSize = NSSize(width: 360, height: 640)
    self.title = "SME Copilot"
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
