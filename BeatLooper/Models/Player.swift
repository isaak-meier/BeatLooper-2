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

// MARK: - Thread-Safe AVPlayer Wrapper
class ThreadSafeAVPlayer {
    private let player: AVPlayer
    
    init() {
        self.player = AVPlayer()
    }
    
    init(playerItem: AVPlayerItem) {
        self.player = AVPlayer(playerItem: playerItem)
    }
    
    // MARK: - Thread-Safe Properties
    var rate: Float {
        get { 
            if Thread.isMainThread {
                return player.rate
            } else {
                return DispatchQueue.main.sync { player.rate }
            }
        }
    }
    
    var currentItem: AVPlayerItem? {
        get { 
            if Thread.isMainThread {
                return player.currentItem
            } else {
                return DispatchQueue.main.sync { player.currentItem }
            }
        }
    }
    
    var currentTime: CMTime {
        get { 
            if Thread.isMainThread {
                return player.currentTime()
            } else {
                return DispatchQueue.main.sync { player.currentTime() }
            }
        }
    }
    
    // MARK: - Thread-Safe Methods
    func play() {
        if Thread.isMainThread {
            player.play()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.player.play()
            }
        }
    }
    
    func pause() {
        if Thread.isMainThread {
            player.pause()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.player.pause()
            }
        }
    }
    
    func seek(to time: CMTime) {
        if Thread.isMainThread {
            player.seek(to: time)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.player.seek(to: time)
            }
        }
    }
    
    func replaceCurrentItem(with item: AVPlayerItem?) {
        if Thread.isMainThread {
            player.replaceCurrentItem(with: item)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.player.replaceCurrentItem(with: item)
            }
        }
    }
    
    func addPeriodicTimeObserver(forInterval interval: CMTime, queue: DispatchQueue?, using block: @escaping @Sendable (CMTime) -> Void) -> Any {
        if Thread.isMainThread {
            return player.addPeriodicTimeObserver(forInterval: interval, queue: queue, using: block)
        } else {
            return DispatchQueue.main.sync {
                return player.addPeriodicTimeObserver(forInterval: interval, queue: queue, using: block)
            }
        }
    }
    
    func addBoundaryTimeObserver(forTimes times: [NSValue], queue: DispatchQueue?, using block: @escaping @Sendable () -> Void) -> Any {
        if Thread.isMainThread {
            return player.addBoundaryTimeObserver(forTimes: times, queue: queue, using: block)
        } else {
            return DispatchQueue.main.sync {
                return player.addBoundaryTimeObserver(forTimes: times, queue: queue, using: block)
            }
        }
    }
    
    func removeTimeObserver(_ observer: Any) {
        if Thread.isMainThread {
            player.removeTimeObserver(observer)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.player.removeTimeObserver(observer)
            }
        }
    }
}

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
actor Player: NSObject {

    // MARK: - Properties
    private var player: ThreadSafeAVPlayer?
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
        return songs[currentSongIndex].title
    }
    
    // MARK: - Initialization
    init(songs: [Beat]) {
        super.init()
        self.songs = songs
        Task {
            await setupPlayer()
        }
    }
    
    init(delegates: [PlayerDelegate], songs: [Beat]) {
        super.init()
        self.delegates = delegates
        self.songs = songs
        Task {
            await setupPlayer()
        }
    }
    
    deinit {
        Task {
            await removeTimeObserver()
        }
    }
    
    // MARK: - Setup
    private func setupPlayer() async {
        guard !songs.isEmpty else { return }
        
        player = ThreadSafeAVPlayer()
        setupAudioSession()
        await loadCurrentSong()
        await setupTimeObserver()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error setting up audio session: \(error)")
        }
    }
    
    private func setupTimeObserver() async {
        guard let player = player else { return }
        
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                await self?.updateProgress(time: time)
            }
        }
    }
    
    private func removeTimeObserver() async {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }
    
    // MARK: - Song Loading
    private func loadCurrentSong() async {
        guard currentSongIndex < songs.count else { return }
        
        let song = songs[currentSongIndex]
        guard let urlString = song.fileUrl, let url = URL(string: urlString) else {
            print("No URL for song: \(song.title ?? "Unknown")")
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        player?.replaceCurrentItem(with: playerItem)
        
        // Notify delegates
        notifyDelegates { $0.playerDidChangeSongTitle(song.title ?? "Unknown") }
        notifyDelegates { $0.playerDidChangeState(playerState) }
        
        // Add observer for item status
        playerItem.addObserver(self, forKeyPath: "status", options: [NSKeyValueObservingOptions.new], context: nil)
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
    
    func skipForward() async -> Bool {
        guard !songs.isEmpty else { return false }
        
        currentSongIndex = (currentSongIndex + 1) % songs.count
        await loadCurrentSong()
        return true
    }
    
    func skipBackward() async -> Bool {
        guard !songs.isEmpty else { return false }
        
        currentSongIndex = currentSongIndex > 0 ? currentSongIndex - 1 : songs.count - 1
        await loadCurrentSong()
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
            Task { @MainActor in
                await self?.handleLoopEnd()
            }
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
    func changeCurrentSongTo(_ song: Beat) async -> Bool {
        guard let index = songs.firstIndex(of: song) else { return false }
        
        currentSongIndex = index
        await loadCurrentSong()
        return true
    }
    
    func addSongToQueue(_ song: Beat) -> Bool {
        songs.append(song)
        notifyDelegates { $0.requestTableViewUpdate() }
        return true
    }
    
    func removeSelectedSongs() async {
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
            await loadCurrentSong()
        }
        
        notifyDelegates { $0.requestTableViewUpdate() }
        notifyDelegates { $0.selectedIndexesChanged(selectedIndexes.count) }
    }
    
    // MARK: - Progress
    func getProgressForCurrentItem() -> Progress? {
        guard let player = player,
              let duration = player.currentItem?.duration else { return nil }
        
        let currentTime = player.currentTime
        let progress = CMTimeGetSeconds(currentTime) / CMTimeGetSeconds(duration)
        
        let progressObj = Progress(totalUnitCount: 100)
        progressObj.completedUnitCount = Int64(progress * 100)
        return progressObj
    }
    
    // MARK: - Helper Methods
    private func updateProgress(time: CMTime) async {
        guard let duration = player?.currentItem?.duration else { return }
        
        let progress = CMTimeGetSeconds(time) / CMTimeGetSeconds(duration)
        notifyDelegates { $0.didUpdateCurrentProgressTo(progress) }
        notifyDelegates { $0.requestProgressBarUpdate() }
    }
    
    private func handleLoopEnd() async {
        guard let player = player,
              let loopTimeRange = loopTimeRange else { return }
        
        player.seek(to: loopTimeRange.start)
    }
    
    private func notifyDelegates(_ action: (PlayerDelegate) -> Void) {
        delegates.forEach(action)
    }
    
    // MARK: - KVO
    nonisolated override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let playerItem = object as? AVPlayerItem {
                let status = playerItem.status
                Task { @MainActor in
                    await self.notifyDelegates { $0.currentItemDidChangeStatus(status) }
                }
            }
        }
    }
}

// MARK: - Table View Data Source Methods
extension Player {
    
    func getNumberOfSongs() -> Int {
        return songs.count
    }
    
    func getSongAtIndex(_ index: Int) -> Beat? {
        guard index < songs.count else { return nil }
        return songs[index]
    }
    
    func isCurrentSongAtIndex(_ index: Int) -> Bool {
        return index == currentSongIndex
    }
    
    func isIndexSelected(_ index: Int) -> Bool {
        return selectedIndexes.contains(index)
    }
    
    func toggleSelectionAtIndex(_ index: Int) {
        if selectedIndexes.contains(index) {
            selectedIndexes.remove(index)
        } else {
            selectedIndexes.insert(index)
        }
        notifyDelegates { $0.selectedIndexesChanged(selectedIndexes.count) }
    }
}
