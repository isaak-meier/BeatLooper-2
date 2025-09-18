//
//  PlayerViewController.swift
//  BeatLooper 2
//
//  Created by Isaak Meier on 5/6/21.
//  Migrated to Swift
//

import UIKit
import MediaPlayer
import CoreMedia

class PlayerViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var songProgressBar: UIProgressView!
    @IBOutlet weak var loopButton: UIButton!
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var playerStatusLabel: UILabel!
    @IBOutlet weak var queueTableView: UITableView!
    @IBOutlet weak var skipForwardButton: UIButton!
    @IBOutlet weak var skipBackButton: UIButton!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var songProgressSlider: UISlider!
    
    // MARK: - Properties
    weak var coordinator: Coordinator?
    private var userIsHoldingSlider: Bool = false
    private var sliderUpdatesToIgnoreCount: Int = 0
    private var playerModel: Player?
    
    // MARK: - Initialization
    init(coordinator: Coordinator) {
        super.init(nibName: nil, bundle: nil)
        self.coordinator = coordinator
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let state = playerModel?.playerState {
            playerDidChangeState(state)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loopButton.imageView?.contentMode = .scaleAspectFit
    }
    
    // MARK: - Setup
    private func setupUI() {
        queueTableView.delegate = playerModel
        queueTableView.dataSource = playerModel
        queueTableView.isEditing = true
        queueTableView.allowsMultipleSelectionDuringEditing = true
    }
    
    // MARK: - Public Methods
    func setup(player: Player) {
        self.playerModel = player
        _ = player.togglePlayOrPause()
        if let state = player.playerState {
            playerDidChangeState(state)
        }
    }
    
    func startLoopWithTimeRange(_ timeRange: CMTimeRange) {
        guard let player = playerModel else { return }
        
        let success = player.startLoopingTimeRange(timeRange)
        if !success {
            print("Loop failed.")
            handleErrorStartingLoop()
        }
    }
    
    func stopLooping() {
        playerModel?.stopLooping()
    }
    
    func changeCurrentSongTo(_ newSong: Beat) {
        guard let player = playerModel else { return }
        
        if player.currentSong != newSong.title {
            _ = player.changeCurrentSongTo(newSong)
        }
    }
    
    func addSongToQueue(_ song: Beat) {
        playerModel?.addSongToQueue(song)
        queueTableView.reloadData()
    }
    
    // MARK: - Private Methods
    private func updateNowPlayingInfoCenterWithTitle(_ title: String?) {
        let infoCenter = MPNowPlayingInfoCenter.default()
        if let title = title {
            let nowPlayingInfo: [String: Any] = [MPMediaItemPropertyTitle: title]
            infoCenter.nowPlayingInfo = nowPlayingInfo
        }
    }
    
    private func handleExistenceError() {
        let alert = UIAlertController(
            title: "Error",
            message: "Sorry, we lost this file. Shittisgone. Please delete and re-add.",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "Haha, Ok", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    private func updatePlayButtonFromState(_ state: PlayerState) {
        switch state {
        case .songPaused, .loopPaused:
            animateButtonToPlayIcon(shouldAnimateToPlayIcon: true)
        case .songPlaying, .loopPlaying:
            animateButtonToPlayIcon(shouldAnimateToPlayIcon: false)
        case .empty:
            break
        }
    }
    
    private func updateButtonsWithState(_ state: PlayerState) {
        switch state {
        case .loopPlaying, .loopPaused:
            skipForwardButton.isHidden = true
            removeButton.isHidden = true
            queueTableView.isEditing = false
        default:
            skipForwardButton.isHidden = false
            removeButton.isHidden = false
            queueTableView.isEditing = true
        }
    }
    
    private func updateSongSubtitleWithState(_ state: PlayerState) {
        switch state {
        case .songPlaying:
            playerStatusLabel.text = "Now Playing"
        case .songPaused:
            playerStatusLabel.text = "Song Paused"
        case .loopPaused:
            playerStatusLabel.text = "Loop Paused"
        case .loopPlaying:
            playerStatusLabel.text = "Now Looping"
        case .empty:
            playerStatusLabel.text = "Just chillin'"
        }
    }
    
    private func setupProgressBar() {
        print("Setting up progress bar")
        if let progress = playerModel?.getProgressForCurrentItem() {
            songProgressBar.observedProgress = progress
        }
        songProgressSlider.value = 0
    }
    
    private func animateButtonToPlayIcon(_ shouldAnimateToPlayIcon: Bool) {
        UIView.transition(with: playButton, duration: 0.1, options: .transitionCrossDissolve) {
            if shouldAnimateToPlayIcon {
                self.playButton.setImage(UIImage(named: "icons8-play-button-100"), for: .normal)
            } else {
                self.playButton.setImage(UIImage(named: "icons8-pause-button-100"), for: .normal)
            }
        }
    }
    
    private func handleErrorStartingLoop() {
        let alert = UIAlertController(
            title: "Ay va voi",
            message: "Hey Buddy, we couldn't start the loop. The song probably couldn't be looped between the bars that you provided.",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "Haha, Ok", style: .default)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    @IBAction func playOrPauseSong(_ sender: UIButton) {
        guard let player = playerModel else { return }
        
        let success = player.togglePlayOrPause()
        if success {
            updatePlayButtonFromState(player.playerState)
        } else {
            print("Play/pause failed on empty player")
        }
    }
    
    @IBAction func skipBackButtonTapped(_ sender: UIButton) {
        guard let player = playerModel else { return }
        
        let success = player.skipBackward()
        if !success {
            print("Skipping backward failed")
        }
    }
    
    @IBAction func skipForwardButtonTapped(_ sender: UIButton) {
        guard let player = playerModel else { return }
        
        let success = player.skipForward()
        if !success {
            print("Skipping forward failed")
        }
        queueTableView.reloadData()
    }
    
    @IBAction func loopButtonTapped(_ sender: UIButton) {
        guard let player = playerModel, player.playerState != .empty else {
            print("Player state empty")
            return
        }
        
        let model = BeatModel()
        if let songToLoop = model.getSongFromSongName(songTitleLabel.text ?? "") {
            let playerIsLooping = player.playerState == .loopPlaying || player.playerState == .loopPaused
            coordinator?.openLooperViewForSong(songToLoop, isLooping: playerIsLooping)
        } else {
            print("ok")
        }
    }
    
    @IBAction func removeButtonTapped(_ sender: UIButton) {
        if removeButton.currentTitle == "Remove" {
            queueTableView.reloadData()
            removeButton.setTitle("Add Songs", for: .normal)
            playerModel?.removeSelectedSongs()
        } else {
            coordinator?.showAddSongsView()
        }
    }
    
    @IBAction func songSliderDidTouchDown(_ sender: UISlider) {
        userIsHoldingSlider = true
    }
    
    @IBAction func songSliderWasReleased(_ sender: UISlider) {
        if playerModel?.playerState == .empty {
            playerStatusLabel.text = "Just chillin' ;)"
        } else {
            playerModel?.seekToProgressValue(songProgressSlider.value)
            sliderUpdatesToIgnoreCount = 5
        }
        userIsHoldingSlider = false
    }
}

// MARK: - PlayerDelegate
extension PlayerViewController: PlayerDelegate {
    
    func playerDidChangeSongTitle(_ songTitle: String) {
        songTitleLabel.text = songTitle
        updateNowPlayingInfoCenterWithTitle(songTitle)
    }
    
    func playerDidChangeState(_ state: PlayerState) {
        updatePlayButtonFromState(state)
        updateSongSubtitleWithState(state)
        updateButtonsWithState(state)
        
        if state == .empty {
            // Please kill me
            coordinator?.playerViewControllerRequestsDeath()
        }
    }
    
    func currentItemDidChangeStatus(_ status: AVPlayerItem.Status) {
        switch status {
        case .readyToPlay:
            print("Item ready to play")
            setupProgressBar()
        case .failed:
            playerStatusLabel.text = "Failed to load song. Please delete & re-add."
            print("Failed. Examine AVPlayerItem.error")
        case .unknown:
            print("Not ready")
        @unknown default:
            break
        }
    }
    
    func didUpdateCurrentProgressTo(_ fractionCompleted: Double) {
        if !userIsHoldingSlider {
            songProgressBar.progress = Float(fractionCompleted)
            
            // We ignore a few updates when we seek to a new time because
            // there's a gross visual glitch otherwise
            if sliderUpdatesToIgnoreCount == 0 {
                songProgressSlider.value = Float(fractionCompleted)
            } else {
                sliderUpdatesToIgnoreCount -= 1
            }
        }
    }
    
    func requestTableViewUpdate() {
        queueTableView.reloadData()
    }
    
    func requestProgressBarUpdate() {
        songProgressSlider.value = 0.0
        songProgressBar.progress = 0.0
        setupProgressBar()
    }
    
    func selectedIndexesChanged(_ count: Int) {
        if count == 0 {
            removeButton.setTitle("Add Songs", for: .normal)
        } else {
            removeButton.setTitle("Remove", for: .normal)
        }
    }
}
