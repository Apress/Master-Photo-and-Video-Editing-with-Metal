/*
See the LICENSE.txt file for this sample’s licensing information.
*/


import Foundation
import SwiftUI
import PhotosUI

struct MediaPicker: View {
    
    enum MediaType {
        case image
        case video
    }
    
    private let handler: (URL) -> Void
    private let title: String
    private let mediaType: MediaType
    
    init<T>(title: T, mediaType: MediaType = .image, handler: @escaping (URL) -> Void) where T: StringProtocol {
        self.handler = handler
        self.mediaType = mediaType
        self.title = String(title)
    }
    
    #if os(iOS)
    
    class PickerDelegateHolder: ObservableObject {
        var pickerDelegate: ImagePickerDelegate?
    }
    
    @StateObject private var pickerDelegateHolder = PickerDelegateHolder()
    
    class ImagePickerDelegate: PHPickerViewControllerDelegate {
        private weak var presenter: UIViewController?
        private let handler: (URL) -> Void
        init(presenter: UIViewController, imagePickedHandler: @escaping (URL) -> Void) {
            self.presenter = presenter
            self.handler = imagePickedHandler
        }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            self.presenter?.dismiss(animated: true, completion: nil)
            if results.count == 1 {
                let result = results[0]
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier, completionHandler: { url, error in
                    if let url = url {
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(url.pathExtension)
                        do {
                            try FileManager.default.copyItem(at: url, to: tempURL)
                            DispatchQueue.main.async {
                                self.handler(tempURL)
                            }
                        } catch {
                            print(error)
                        }
                    }
                })
            }
        }
    }
    
    #endif
    
    var body: some View {
        #if os(iOS)
        return Button(title, action: { [handler] in
            if let rootWindow = UIApplication.shared.windows.first(where: { $0.isHidden == false }), let viewController = rootWindow.rootViewController {
                var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
                configuration.filter = self.mediaType == .image ? .images : .videos
                configuration.selectionLimit = 1
                configuration.preferredAssetRepresentationMode = .current
                let picker = PHPickerViewController(configuration: configuration)
                let delegate = ImagePickerDelegate(presenter: viewController, imagePickedHandler: handler)
                picker.delegate = delegate
                self.pickerDelegateHolder.pickerDelegate = delegate
                viewController.present(picker, animated: true, completion: nil)
            }
        })
        #elseif os(macOS)
        return Button(title, action: { [handler] in
            let openPanel = NSOpenPanel()
            openPanel.allowsMultipleSelection = false
            openPanel.allowedContentTypes = self.mediaType == .image ? [.jpeg, .png, .heic, .bmp, .webP, .gif] : [.video, .mpeg4Movie, .quickTimeMovie, .appleProtectedMPEG4Video, .mpeg2Video, .avi]
            if openPanel.runModal() == .OK, let url = openPanel.url {
                handler(url)
            }
        })
        #else
        #error("Unsupported Platform")
        #endif
    }
}
