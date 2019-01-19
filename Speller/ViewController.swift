//
//  ViewController.swift
//  Speller
//
//  Created by Qinhong Chen on 7/13/18.
//  Copyright © 2018 Qinhong Chen. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UITextFieldDelegate, AVSpeechSynthesizerDelegate {
	
	@IBOutlet weak var correctIndicator: UILabel!
	@IBOutlet weak var correctAnswerLabel: UILabel!
	@IBOutlet weak var correctSpellingLabel: UILabel!
	@IBOutlet weak var yourAnswerLabel: UILabel!
	@IBOutlet weak var yourSpellingLabel: UILabel!
	@IBOutlet weak var definitionIndicator: UILabel!
	@IBOutlet weak var definitionLabel: UILabel!
	@IBOutlet weak var textField: UITextField!
	@IBOutlet weak var bottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var newWordButton: UIButton!
	@IBOutlet var speechButtons: [UIButton]!
	
	var dictionary = [Word]()
	var currentWord: Word!
	let synth = AVSpeechSynthesizer()

	override func viewDidLoad() {
		super.viewDidLoad()
		
		setAnswersVisible(visibility: false)
		textField.delegate = self
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
		
		synth.delegate = self
		loadDictionary()
	}
	
	private func loadDictionary() {
		if let path = Bundle.main.path(forResource: "dictionary", ofType: "tsv") {
			do {
				let data = try String(contentsOfFile: path, encoding: .utf8)
				let lines = data.components(separatedBy: .newlines)
				for entry in lines {
					let parts = entry.components(separatedBy: "\t")
					if parts.count == 4 {
						let newWord = Word(word: parts[0], definition: parts[3], partOfSpeech: parts[1], origin: parts[2])
						dictionary.append(newWord)
					}
				}
			} catch {
				print(error)
			}
			currentWord = generateRandomWord()
		}
	}
	
	private func setAnswersVisible(visibility: Bool) {
		correctIndicator.isHidden = !visibility
		correctAnswerLabel.isHidden = !visibility
		correctSpellingLabel.isHidden = !visibility
		yourAnswerLabel.isHidden = !visibility
		yourSpellingLabel.isHidden = !visibility
		definitionIndicator.isHidden = !visibility
		definitionLabel.isHidden = !visibility
		newWordButton.isHidden = !visibility
	}
	
	private func setButtonsEnabled(enabled: Bool) {
		speechButtons.forEach {$0.isEnabled = enabled}
	}
	
	private func generateRandomWord() -> Word? {
		if dictionary.isEmpty {
			return nil
		}
		return dictionary[Int(arc4random_uniform(UInt32(dictionary.count)))]
	}
	
	private func sayWord(string: String) {
		let utterance = AVSpeechUtterance(string: string)
		utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
		synth.speak(utterance)
		setButtonsEnabled(enabled: false)
	}
	
	@IBAction func hearWordButtonPressed() {
		sayWord(string: currentWord.word)
	}
	
	@IBAction func partOfSpeechButtonPressed() {
		sayWord(string: currentWord.partOfSpeech)
	}
	
	@IBAction func definitionPressed() {
		sayWord(string: currentWord.definition)
	}
	
	@IBAction func originPressed() {
		sayWord(string: currentWord.origin)
	}
	
	@IBAction func newWordButtonPressed() {
		setAnswersVisible(visibility: false)
		textField.text = ""
		currentWord = generateRandomWord()
		textField.isEnabled = true
		sayWord(string: currentWord.word)
		textField.becomeFirstResponder()
	}
	
	func textFieldShouldReturn(_ field: UITextField) -> Bool {
		if field == textField {
			textField.resignFirstResponder()
			if textField?.text != nil, currentWord.word.caseInsensitiveCompare(textField.text!) == .orderedSame {
				correctIndicator.text = "Correct!"
				correctIndicator.textColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
				correctSpellingLabel.text = currentWord.word
				yourSpellingLabel.text = textField.text!
			}
			else if textField?.text != nil {
				correctIndicator.text = "Incorrect."
				correctIndicator.textColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
				correctSpellingLabel.text = currentWord.word
				yourSpellingLabel.text = textField.text!
			}
			definitionLabel.text = currentWord.dictionaryDefinition()
			setAnswersVisible(visibility: true)
			textField.isEnabled = false
			return false
		}
		return true
	}
	
	func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
		setButtonsEnabled(enabled: true)
	}
	
	func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
		setButtonsEnabled(enabled: true)
	}
	
	@objc func keyboardWillShow(notification: NSNotification) {
		let info = notification.userInfo!
		let keyboardFrame: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
		
		UIView.animate(withDuration: 0.1, animations: { () -> Void in
			self.bottomConstraint.constant = keyboardFrame.size.height - self.view.safeAreaInsets.bottom
		})
	}
	
	@objc func keyboardWillHide(notification: NSNotification) {
		UIView.animate(withDuration: 0.1, animations: { () -> Void in
			self.bottomConstraint.constant = 0
		})
	}
}

extension Word {
	func dictionaryDefinition() -> String {
		var def = ""
		switch partOfSpeech {
		case "noun": def = "(n.) "
		case "verb": def = "(v.) "
		case "adjective": def = "(adj.) "
		case "adverb": def = "(adv.) "
		default: def = "(\(partOfSpeech)) "
		}
		def += definition
		return def
	}
}
