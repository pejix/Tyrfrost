import PhotosUI
import SwiftUI
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var cfg = PHPickerConfiguration(photoLibrary: .shared())
        cfg.selectionLimit = 1; cfg.filter = .images
        let vc = PHPickerViewController(configuration: cfg)
        vc.delegate = context.coordinator; return vc
    }
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker; init(_ parent: ImagePicker){ self.parent = parent }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let item = results.first?.itemProvider else { return }
            if item.canLoadObject(ofClass: UIImage.self) {
                item.loadObject(ofClass: UIImage.self) { img, _ in
                    DispatchQueue.main.async { self.parent.image = img as? UIImage }
                }
            }
        }
    }
}
