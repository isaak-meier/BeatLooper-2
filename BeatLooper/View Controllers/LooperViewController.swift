//
//  LooperViewController.swift
//  BeatLooper 2
//
//  Created by Isaak Meier on 12/30/21.
//  Migrated to Swift
//

import UIKit
import CoreMedia

class LooperViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tempoTextField: UITextField!
    @IBOutlet weak var startBarTextField: UITextField!
    @IBOutlet weak var endBarTextField: UITextField!
    @IBOutlet weak var loopButton: UIButton!
    
    // MARK: - Properties
    var song: Beat!
    weak var coordinator: Coordinator?
    private var model: BeatModel!
    private var isLooping: Bool = false
    private var tempo: Int = 0
    private var startBar: Int = 0
    private var endBar: Int = 0
    
    // MARK: - Initialization
    init(song: Beat, isLooping: Bool) {
        super.init(nibName: nil, bundle: nil)
        self.song = song
        self.model = BeatModel()
        self.isLooping = isLooping
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardToolbar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        populateTextFields()
    }
    
    // MARK: - Setup
    private func setupKeyboardToolbar() {
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        
        let flexBarButton = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        
        let doneBarButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneBarButtonPressed)
        )
        
        keyboardToolbar.items = [flexBarButton, doneBarButton]
        tempoTextField.inputAccessoryView = keyboardToolbar
        startBarTextField.inputAccessoryView = keyboardToolbar
        endBarTextField.inputAccessoryView = keyboardToolbar
    }
    
    private func populateTextFields() {
        let userDefaults = UserDefaults.standard
        let lastStartBar = userDefaults.integer(forKey: "startBar")
        let lastEndBar = userDefaults.integer(forKey: "endBar")
        
        if lastStartBar >= 0 {
            startBarTextField.text = "\(lastStartBar)"
            startBar = lastStartBar
        }
        
        if lastEndBar >= 0 && lastEndBar > lastStartBar {
            endBarTextField.text = "\(lastEndBar)"
            endBar = lastEndBar
        }
        
        print("getting tempo from \(song.title ?? "Unknown")")
        let savedTempo = Int(song.tempo)
        if savedTempo > 0 && savedTempo != tempo {
            tempo = savedTempo
            DispatchQueue.main.async {
                self.tempoTextField.text = "\(self.tempo)"
            }
        }
    }
    
    // MARK: - Actions
    @objc private func doneBarButtonPressed() {
        // Save all the values
        if let tempoStr = tempoTextField.text {
            tempo = Int(tempoStr) ?? 0
            model.saveTempo(tempo, forSong: song.objectID)
        }
        
        let userDefaults = UserDefaults.standard
        if let startBarStr = startBarTextField.text {
            startBar = Int(startBarStr) ?? 0
            userDefaults.set(startBar, forKey: "startBar")
        }
        
        if let endBarStr = endBarTextField.text {
            endBar = Int(endBarStr) ?? 0
            userDefaults.set(endBar, forKey: "endBar")
        }
        
        // We don't know who pressed done, so call it for all of them
        tempoTextField.resignFirstResponder()
        startBarTextField.resignFirstResponder()
        endBarTextField.resignFirstResponder()
    }
    
    @IBAction func loopButtonTapped(_ sender: UIButton) {
        if !isLooping {
            let timeRangeOfLoop = BeatModel.timeRangeFromBars(
                startBar: startBar,
                endBar: endBar,
                tempo: tempo
            )
            
            if CMTIMERANGE_IS_INVALID(timeRangeOfLoop) ||
               CMTIMERANGE_IS_EMPTY(timeRangeOfLoop) ||
               CMTIMERANGE_IS_INDEFINITE(timeRangeOfLoop) ||
               tempo <= 0 {
                handleTimeRangeError()
            } else {
                isLooping = true
                loopButton.setTitle("Stop Looping", for: .normal)
                coordinator?.dismissLooperViewAndBeginLoopingTimeRange(timeRangeOfLoop)
            }
        } else {
            isLooping = false
            loopButton.setTitle("Start Loop!", for: .normal)
            coordinator?.dismissLooperViewAndStopLoop()
        }
    }
    
    // MARK: - Private Methods
    private func handleTimeRangeError() {
        let alert = UIAlertController(
            title: "Ah ah ah~",
            message: "Hey Buddy, you provided an invalid time range. Make sure to set the tempo, start bar, and end bar, or else I can't be loopin' with much success.\n\n You need to provide the right tempo, 0 as the start bar and 4 as the end bar is a pretty safe default.",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "Haha, Ok", style: .default)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension LooperViewController: UITextFieldDelegate {
    // Add any text field delegate methods if needed
}
