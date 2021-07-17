//
//  ViewController.swift
//  Instafilter
//
//  Created by Igor Chernyshov on 14.07.2021.
//

import UIKit
import CoreImage

final class ViewController: UIViewController {

	// MARK: - Outlets
	@IBOutlet var imageView: UIImageView!
	@IBOutlet var intensity: UISlider!
	@IBOutlet var changeFilterButton: UIButton!

	// MARK: - Properties
	private var currentImage: UIImage!
	private var context: CIContext!
	private var currentFilter: CIFilter!

	// MARK: - Lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Instafilter"
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(importPicture))
		context = CIContext()
		currentFilter = CIFilter(name: "CISepiaTone")
	}

	// MARK: - Working with filters
	private func applyProcessing() {
		guard let image = currentFilter.outputImage else { return }

		let inputKeys = currentFilter.inputKeys
		if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(intensity.value, forKey: kCIInputIntensityKey) }
		if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(intensity.value * 200, forKey: kCIInputRadiusKey) }
		if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(intensity.value * 10, forKey: kCIInputScaleKey) }
		if inputKeys.contains(kCIInputCenterKey) { currentFilter.setValue(CIVector(x: currentImage.size.width * 0.5, y: currentImage.size.height * 0.5), forKey: kCIInputCenterKey) }

		guard let cgimg = context.createCGImage(image, from: image.extent) else { return }

		let processedImage = UIImage(cgImage: cgimg)
		self.imageView.image = processedImage
	}

	private func setFilter(action: UIAlertAction) {
		guard currentImage != nil, let actionTitle = action.title else { return }

		currentFilter = CIFilter(name: actionTitle)

		let beginImage = CIImage(image: currentImage)
		currentFilter.setValue(beginImage, forKey: kCIInputImageKey)

		changeFilterButton.setTitle("Filter: \(actionTitle)", for: .normal)

		applyProcessing()
	}

	// MARK: - Selectors
	@IBAction func intensityChanged(_ sender: Any) {
		applyProcessing()
	}

	@IBAction func changeFilter(_ sender: Any) {
		showSelectFiltersAlert()
	}

	@IBAction func save(_ sender: Any) {
		guard let image = imageView.image else {
			showNoImageAlert()
			return
		}
		UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
	}

	@objc private func importPicture() {
		let picker = UIImagePickerController()
		picker.allowsEditing = true
		picker.delegate = self
		present(picker, animated: UIView.areAnimationsEnabled)
	}

	@objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
		if let error = error {
			showSaveErrorAlert(error: error)
		} else {
			showSavedSuccessfulAlert()
		}
	}

	// MARK: - Alerts
	private func showNoImageAlert() {
		let alertController = UIAlertController(title: "Save error", message: "There is no image to save", preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "OK", style: .default))
		present(alertController, animated: UIView.areAnimationsEnabled)
	}

	private func showSelectFiltersAlert() {
		let alertController = UIAlertController(title: "Choose filter", message: nil, preferredStyle: .actionSheet)
		alertController.addAction(UIAlertAction(title: "CIBumpDistortion", style: .default, handler: setFilter))
		alertController.addAction(UIAlertAction(title: "CIGaussianBlur", style: .default, handler: setFilter))
		alertController.addAction(UIAlertAction(title: "CIPixellate", style: .default, handler: setFilter))
		alertController.addAction(UIAlertAction(title: "CISepiaTone", style: .default, handler: setFilter))
		alertController.addAction(UIAlertAction(title: "CITwirlDistortion", style: .default, handler: setFilter))
		alertController.addAction(UIAlertAction(title: "CIUnsharpMask", style: .default, handler: setFilter))
		alertController.addAction(UIAlertAction(title: "CIVignette", style: .default, handler: setFilter))
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		present(alertController, animated: UIView.areAnimationsEnabled)
	}

	private func showSaveErrorAlert(error: Error) {
		let alertController = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "OK", style: .default))
		present(alertController, animated: UIView.areAnimationsEnabled)
	}

	private func showSavedSuccessfulAlert() {
		let alertController = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "OK", style: .default))
		present(alertController, animated: UIView.areAnimationsEnabled)
	}
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	func imagePickerController(_ picker: UIImagePickerController,
							   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		guard let image = info[.editedImage] as? UIImage else { return }
		dismiss(animated: UIView.areAnimationsEnabled)
		UIView.animate(withDuration: 0.5) {
			self.imageView.alpha = 0
		} completion: { _ in
			UIView.animate(withDuration: 0.5) {
				self.imageView.alpha = 1
			} completion: { _ in
				self.currentImage = image

				let beginImage = CIImage(image: self.currentImage)
				self.currentFilter.setValue(beginImage, forKey: kCIInputImageKey)

				self.applyProcessing()
			}
		}
	}
}
