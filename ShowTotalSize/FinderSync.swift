import Cocoa
import FinderSync

class FinderSyncExtension: FIFinderSync {

    override init() {
        super.init()
        
        NSLog("FinderSync() launched from %@", Bundle.main.bundlePath as NSString)
        
        // Monitor all directories.
        FIFinderSyncController.default().directoryURLs = Set([URL(fileURLWithPath: "/")])
    }
    
    // MARK: - Primary Finder Sync protocol methods
    
    override func beginObservingDirectory(at url: URL) {
        NSLog("beginObservingDirectoryAtURL: %@", url.path as NSString)
    }
    
    override func endObservingDirectory(at url: URL) {
        NSLog("endObservingDirectoryAtURL: %@", url.path as NSString)
    }
    
    // MARK: - Menu and toolbar item support
    
    override var toolbarItemName: String {
        return "FinderSy"
    }
    
    override var toolbarItemToolTip: String {
        return "FinderSy: Click the toolbar item for a menu."
    }
    
    override var toolbarItemImage: NSImage {
        return NSImage(named: NSImage.cautionName)!
    }
    
    // Override 'menu' method to add 'Show Total Size' menu item
       override func menu(for menuKind: FIMenuKind) -> NSMenu {
           let menu = NSMenu(title: "")
           if menuKind == .contextualMenuForItems {
               menu.addItem(withTitle: "Show Total Size", action: #selector(showTotalSize(_:)), keyEquivalent: "")
           }
           return menu
       }

    
    @IBAction func showTotalSize(_ sender: AnyObject?) {
        guard let selectedItemURLs = FIFinderSyncController.default().selectedItemURLs() else {
            NSLog("No items selected")
            return
        }

        var detailedSizes = [(URL, Int64)]()
        let totalSize = selectedItemURLs.reduce(0) { total, url in
            do {
                let size = try FileManager.default.allocatedSize(of: url)
                detailedSizes.append((url, size))
                return total + Int(size)
            } catch {
                NSLog("Error calculating size for \(url): \(error)")
                return total
            }
        }

        detailedSizes.sort { $0.1 > $1.1 } // Sort from largest to smallest

        DispatchQueue.main.async {
            self.showAlert(size: Int64(totalSize), detailedSizes: detailedSizes)
        }
    }


    func showAlert(size: Int64, detailedSizes: [(URL, Int64)]) {
        let sizeText = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        
        let maxFilenameLength = 30 // Maximum length of filename
        let detailedText = detailedSizes.map { (url, size) in
            let fileSizeText = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            let truncatedFilename = url.lastPathComponent.truncating(to: maxFilenameLength)
            return "\(truncatedFilename) \(fileSizeText)"
        }.joined(separator: "\n")

        let alert = NSAlert()
        alert.messageText = "Total Size: \(sizeText)"
        alert.informativeText = detailedText
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

extension FileManager {
    func allocatedSize(of url: URL) throws -> Int64 {
        let resources = try url.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey, .totalFileSizeKey])

        if let isDirectory = resources.isDirectory, isDirectory {
            let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey])
            var total: Int64 = 0
            for case let fileURL as URL in enumerator! {
                total += try allocatedSize(of: fileURL)
            }
            return total
        } else {
            // Return the size of a single file.
            return Int64(resources.totalFileSize ?? resources.fileSize ?? 0)
        }
    }
}

extension String {
    func truncating(to length: Int) -> String {
        return (self.count > length) ? self.prefix(length) + "…" : self
    }
}

class SizePopoverViewController: NSViewController {
    var sizeText: String
    var detailedText: String

    init(sizeText: String, detailedText: String) {
        self.sizeText = sizeText
        self.detailedText = detailedText
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let textView = NSTextView()
        textView.isEditable = false
        textView.textStorage?.append(NSAttributedString(string: "Total Size: \(sizeText)\n\n\(detailedText)"))
        view = textView
    }
}
