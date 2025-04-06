import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    
    // 设置窗口初始大小和最小尺寸
    let initialFrame = NSRect(x: 0, y: 0, width: 1024, height: 768)
    let minSize = NSSize(width: 800, height: 600)
    
    // 调整窗口位置使其居中
    let screenFrame = NSScreen.main?.visibleFrame ?? NSRect.zero
    let centeredOrigin = NSPoint(
      x: screenFrame.origin.x + (screenFrame.size.width - initialFrame.size.width) / 2,
      y: screenFrame.origin.y + (screenFrame.size.height - initialFrame.size.height) / 2
    )
    
    let windowFrame = NSRect(origin: centeredOrigin, size: initialFrame.size)
    
    // 应用窗口设置
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.minSize = minSize
    
    // 设置窗口样式
    self.isMovableByWindowBackground = true
    
    // 使用默认标题栏，但使其透明，保留控制按钮的同时不显示标题
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    
    // 设置内容视图填满整个窗口，包括标题栏区域
    self.styleMask.insert(.fullSizeContentView)
    
    // 创建一个透明视图用于处理标题栏区域的鼠标事件，确保可拖动
    if let contentView = self.contentView {
      let titleBarHeight: CGFloat = 28.0
      let titleBarAccessoryView = NSView(frame: NSRect(
        x: 0,
        y: contentView.bounds.height - titleBarHeight,
        width: contentView.bounds.width,
        height: titleBarHeight
      ))
      
      // 设置视图可拖动，但保持透明
      titleBarAccessoryView.wantsLayer = true
      titleBarAccessoryView.layer?.backgroundColor = NSColor.clear.cgColor
      
      // 确保视图随窗口大小调整
      titleBarAccessoryView.autoresizingMask = [.width, .minYMargin]
      
      contentView.addSubview(titleBarAccessoryView)
    }
    
    // 启用窗口大小变化时的平滑缩放效果
    self.animationBehavior = .documentWindow
    
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
