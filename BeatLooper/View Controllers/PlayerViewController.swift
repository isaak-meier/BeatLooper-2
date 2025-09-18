//
//  PlayerViewController.swift
//  BeatLooper 2
//
//  Created by Isaak Meier on 5/6/21.
//  Migrated to Swift
//

import UIKit
import CoreData
import CoreMedia
import MediaPlayer
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
        Task {
            if let state = await playerModel?.playerState {
                playerDidChangeState(state)
            }
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
    func setup(player: Player) async {
        self.playerModel = player
        _ = await player.togglePlayOrPause()
        let state = await player.playerState
        playerDidChangeState(state)
    }
    
    func startLoopWithTimeRange(_ timeRange: CMTimeRange) async {
        guard let player = playerModel else { return }
        
        let success = await player.startLoopingTimeRange(timeRange)
        if !success {
            print("Loop failed.")
            handleErrorStartingLoop()
        }
    }
    
    func stopLooping() async {
        _ = await playerModel?.stopLooping()
    }
    
    func changeCurrentSongTo(_ newSong: Beat) async {
        guard let player = playerModel else { return }
        
        let currentSong = await player.currentSong
        if currentSong != newSong.title {
            _ = await player.changeCurrentSongTo(newSong)
        }
    }
    
    func addSongToQueue(_ song: Beat) async {
        _ = await playerModel?.addSongToQueue(song)
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
            animateButtonToPlayIcon(true)
        case .songPlaying, .loopPlaying:
            animateButtonToPlayIcon(false)
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
    
    private func setupProgressBar() async {
        print("Setting up progress bar")
        if let progress = await playerModel?.getProgressForCurrentItem() {
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
        
        Task {
            let success = await player.togglePlayOrPause()
            if success {
                let state = await player.playerState
                await MainActor.run {
                    updatePlayButtonFromState(state)
                }
            } else {
                print("Play/pause failed on empty player")
            }
        }
    }
    
    @IBAction func skipBackButtonTapped(_ sender: UIButton) {
        guard let player = playerModel else { return }
        
        Task {
            let success = await player.skipBackward()
            if !success {
                print("Skipping backward failed")
            }
        }
    }
    
    @IBAction func skipForwardButtonTapped(_ sender: UIButton) {
        guard let player = playerModel else { return }
        
        Task {
            let success = await player.skipForward()
            if !success {
                print("Skipping forward failed")
            }
            await MainActor.run {
                queueTableView.reloadData()
            }
        }
    }
    
    @IBAction func loopButtonTapped(_ sender: UIButton) {
        guard let player = playerModel else {
            print("Player state empty")
            return
        }
        
        Task {
            let state = await player.playerState
            guard state != .empty else {
                print("Player state empty")
                return
            }
            
            let model = BeatModel()
            if let songToLoop = model.getSongFromSongName(songTitleLabel.text ?? "") {
                let playerIsLooping = state == .loopPlaying || state == .loopPaused
                await MainActor.run {
                    coordinator?.openLooperViewForSong(songToLoop, isLooping: playerIsLooping)
                }
            } else {
                print("ok")
            }
        }
    }
    
    @IBAction func removeButtonTapped(_ sender: UIButton) {
        if removeButton.currentTitle == "Remove" {
            queueTableView.reloadData()
            removeButton.setTitle("Add Songs", for: .normal)
            Task {
                await playerModel?.removeSelectedSongs()
            }
        } else {
            coordinator?.showAddSongsView()
        }
    }
    
    @IBAction func songSliderDidTouchDown(_ sender: UISlider) {
        userIsHoldingSlider = true
    }
    
    @IBAction func songSliderWasReleased(_ sender: UISlider) {
        Task {
            let state = await playerModel?.playerState
            if state == .empty {
                await MainActor.run {
                    playerStatusLabel.text = "Just chillin' ;)"
                }
            } else {
                _ = await playerModel?.seekToProgressValue(songProgressSlider.value)
                await MainActor.run {
                    sliderUpdatesToIgnoreCount = 5
                }
            }
            await MainActor.run {
                userIsHoldingSlider = false
            }
        }
    }
}

// MARK: - PlayerDelegate
extension PlayerViewController: PlayerDelegate {
    
    nonisolated func playerDidChangeSongTitle(_ songTitle: String) {
        Task { @MainActor in
            songTitleLabel.text = songTitle
            updateNowPlayingInfoCenterWithTitle(songTitle)
        }
    }
    
    nonisolated func playerDidChangeState(_ state: PlayerState) {
        Task { @MainActor in
            updatePlayButtonFromState(state)
            updateSongSubtitleWithState(state)
            updateButtonsWithState(state)
            
            if state == .empty {
                // Please kill me
                coordinator?.playerViewControllerRequestsDeath()
            }
        }
    }
    
    nonisolated func currentItemDidChangeStatus(_ status: AVPlayerItem.Status) {
        Task { @MainActor in
            switch status {
            case .readyToPlay:
                print("Item ready to play")
                await setupProgressBar()
            case .failed:
                playerStatusLabel.text = "Failed to load song. Please delete & re-add."
                print("Failed. Examine AVPlayerItem.error")
            case .unknown:
                print("Not ready")
            @unknown default:
                break
            }
        }
    }
    
    nonisolated func didUpdateCurrentProgressTo(_ fractionCompleted: Double) {
        Task { @MainActor in
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
    }
    
    nonisolated func requestTableViewUpdate() {
        Task { @MainActor in
            queueTableView.reloadData()
        }
    }
    
    nonisolated func requestProgressBarUpdate() {
        Task { @MainActor in
            songProgressSlider.value = 0.0
            songProgressBar.progress = 0.0
            await setupProgressBar()
        }
    }
    
    nonisolated func selectedIndexesChanged(_ count: Int) {
        Task { @MainActor in
            if count == 0 {
                removeButton.setTitle("Add Songs", for: .normal)
            } else {
                removeButton.setTitle("Remove", for: .normal)
            }
        }
    }
}
