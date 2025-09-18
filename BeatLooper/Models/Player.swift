//
//  Player.swift
//  BeatLooper 2
//
//  Created by Isaak Meier on 1/4/22.
//  Migrated to Swift
//

import Foundation
import UIKit
import CoreData
import AVFoundation
import CoreMedia

// MARK: - Player State Enum
enum PlayerState {
    case songPlaying
    case songPaused
    case loopPlaying
    case loopPaused
    case empty
}

// MARK: - Player Delegate Protocol
protocol PlayerDelegate: AnyObject {
    func playerDidChangeSongTitle(_ songTitle: String)
    func playerDidChangeState(_ state: PlayerState)
    func currentItemDidChangeStatus(_ status: AVPlayerItem.Status)
    func didUpdateCurrentProgressTo(_ fractionCompleted: Double)
    func requestTableViewUpdate()
    func requestProgressBarUpdate()
    func selectedIndexesChanged(_ count: Int)
}

// MARK: - Player Class
class Player: NSObject {
    
    // MARK: - Properties
    private var player: AVPlayer?
    private var songs: [Beat] = []
    private var currentSongIndex: Int = 0
    private var delegates: [PlayerDelegate] = []
    private var timeObserver: Any?
    private var isLooping: Bool = false
    private var loopTimeRange: CMTimeRange?
    private var selectedIndexes: Set<Int> = []
    
    // MARK: - Computed Properties
    var playerState: PlayerState {
        guard let player = player else { return .empty }
        
        if isLooping {
            return player.rate > 0 ? .loopPlaying : .loopPaused
        } else {
            return player.rate > 0 ? .songPlaying : .songPaused
        }
    }
    
    var currentSong: String? {
        guard currentSongIndex < songs.count else { return nil }
        return songs[currentSongIndex].songName
    }
    
    // MARK: - Initialization
    init(songs: [Beat]) {
        super.init()
        self.songs = songs
        setupPlayer()
    }
    
    init(delegates: [PlayerDelegate], songs: [Beat]) {
        super.init()
        self.delegates = delegates
        self.songs = songs
        setupPlayer()
    }
    
    deinit {
        removeTimeObserver()
    }
    
    // MARK: - Setup
    private func setupPlayer() {
        guard !songs.isEmpty else { return }
        
        player = AVPlayer()
        setupAudioSession()
        loadCurrentSong()
        setupTimeObserver()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error setting up audio session: \(error)")
        }
    }
    
    private func setupTimeObserver() {
        guard let player = player else { return }
        
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.updateProgress(time: time)
        }
    }
    
    private func removeTimeObserver() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }
    
    // MARK: - Song Loading
    private func loadCurrentSong() {
        guard currentSongIndex < songs.count else { return }
        
        let song = songs[currentSongIndex]
        guard let url = song.songURL else {
            print("No URL for song: \(song.songName ?? "Unknown")")
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        player?.replaceCurrentItem(with: playerItem)
        
        // Notify delegates
        notifyDelegates { $0.playerDidChangeSongTitle(song.songName ?? "Unknown") }
        notifyDelegates { $0.playerDidChangeState(playerState) }
        
        // Add observer for item status
        playerItem.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
    }
    
    // MARK: - Player Controls
    func togglePlayOrPause() -> Bool {
        guard let player = player else { return false }
        
        if player.rate > 0 {
            player.pause()
        } else {
            player.play()
        }
        
        notifyDelegates { $0.playerDidChangeState(playerState) }
        return true
    }
    
    func skipForward() -> Bool {
        guard !songs.isEmpty else { return false }
        
        currentSongIndex = (currentSongIndex + 1) % songs.count
        loadCurrentSong()
        return true
    }
    
    func skipBackward() -> Bool {
        guard !songs.isEmpty else { return false }
        
        currentSongIndex = currentSongIndex > 0 ? currentSongIndex - 1 : songs.count - 1
        loadCurrentSong()
        return true
    }
    
    func startLoopingTimeRange(_ timeRange: CMTimeRange) -> Bool {
        guard let player = player else { return false }
        
        isLooping = true
        loopTimeRange = timeRange
        
        // Seek to start of loop
        player.seek(to: timeRange.start)
        
        // Set up boundary time observer for loop end
        let endTime = CMTimeAdd(timeRange.start, timeRange.duration)
        let times = [NSValue(time: endTime)]
        
        player.addBoundaryTimeObserver(forTimes: times, queue: .main) { [weak self] in
            self?.handleLoopEnd()
        }
        
        player.play()
        notifyDelegates { $0.playerDidChangeState(playerState) }
        return true
    }
    
    func stopLooping() -> Bool {
        guard isLooping else { return false }
        
        isLooping = false
        loopTimeRange = nil
        
        notifyDelegates { $0.playerDidChangeState(playerState) }
        return true
    }
    
    func seekToProgressValue(_ value: Float) -> Bool {
        guard let player = player,
              let duration = player.currentItem?.duration else { return false }
        
        let time = CMTimeMultiplyByFloat64(duration, multiplier: Float64(value))
        player.seek(to: time)
        return true
    }
    
    // MARK: - Queue Management
    func changeCurrentSongTo(_ song: Beat) -> Bool {
        guard let index = songs.firstIndex(of: song) else { return false }
        
        currentSongIndex = index
        loadCurrentSong()
        return true
    }
    
    func addSongToQueue(_ song: Beat) -> Bool {
        songs.append(song)
        notifyDelegates { $0.requestTableViewUpdate() }
        return true
    }
    
    func removeSelectedSongs() {
        let sortedIndexes = selectedIndexes.sorted(by: >)
        
        for index in sortedIndexes {
            if index < songs.count {
                songs.remove(at: index)
            }
        }
        
        selectedIndexes.removeAll()
        
        // Adjust current song index if necessary
        if currentSongIndex >= songs.count {
            currentSongIndex = max(0, songs.count - 1)
            loadCurrentSong()
        }
        
        notifyDelegates { $0.requestTableViewUpdate() }
        notifyDelegates { $0.selectedIndexesChanged(selectedIndexes.count) }
    }
    
    // MARK: - Progress
    func getProgressForCurrentItem() -> Progress? {
        guard let player = player,
              let duration = player.currentItem?.duration else { return nil }
        
        let currentTime = player.currentTime()
        let progress = CMTimeGetSeconds(currentTime) / CMTimeGetSeconds(duration)
        
        return Progress(totalUnitCount: 100, completedUnitCount: Int64(progress * 100))
    }
    
    // MARK: - Helper Methods
    private func updateProgress(time: CMTime) {
        guard let duration = player?.currentItem?.duration else { return }
        
        let progress = CMTimeGetSeconds(time) / CMTimeGetSeconds(duration)
        notifyDelegates { $0.didUpdateCurrentProgressTo(progress) }
        notifyDelegates { $0.requestProgressBarUpdate() }
    }
    
    private func handleLoopEnd() {
        guard let player = player,
              let loopTimeRange = loopTimeRange else { return }
        
        player.seek(to: loopTimeRange.start)
    }
    
    private func notifyDelegates(_ action: (PlayerDelegate) -> Void) {
        delegates.forEach(action)
    }
    
    // MARK: - KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let playerItem = object as? AVPlayerItem {
                notifyDelegates { $0.currentItemDidChangeStatus(playerItem.status) }
            }
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension Player: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath)
        let song = songs[indexPath.row]
        
        cell.textLabel?.text = song.songName
        cell.accessoryType = indexPath.row == currentSongIndex ? .checkmark : .none
        cell.backgroundColor = selectedIndexes.contains(indexPath.row) ? .systemBlue.withAlphaComponent(0.3) : .clear
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if selectedIndexes.contains(indexPath.row) {
            selectedIndexes.remove(indexPath.row)
        } else {
            selectedIndexes.insert(indexPath.row)
        }
        
        tableView.reloadRows(at: [indexPath], with: .none)
        notifyDelegates { $0.selectedIndexesChanged(selectedIndexes.count) }
    }
}
