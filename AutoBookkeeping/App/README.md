# App 入口

此目录包含 App 的入口文件和全局配置。

## 文件说明

- `AutoBookkeepingApp.swift` - SwiftUI App 入口
- `AppDelegate.swift` - App 生命周期管理（可选）
- `SceneDelegate.swift` - Scene 管理（可选）

## 待创建文件

创建 Xcode 项目后，主要文件将在这里：

```swift
// AutoBookkeepingApp.swift
import SwiftUI
import SwiftData

@main
struct AutoBookkeepingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Transaction.self, Category.self, Budget.self])
    }
}
```
