//
//  HomeViewController.swift
//  BeatLooper 2
//
//  Created by Isaak Meier on 4/2/21.
//  Migrated to Swift
//

import UIKit

class HomeViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var songTableView: UITableView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var rainbowMusicBanner: UIImageView!
    
    // MARK: - Properties
    var model: BeatModel!
    weak var coordinator: Coordinator?
    private var songs: [Beat] = []
    private var isAddSongsMode: Bool = false
    private var rowSelected: Bool = false
    private var currentlyPlayingSongTitle: String?
    
    // MARK: - Initialization
    init(coordinator: Coordinator, inAddSongsMode: Bool) {
        super.init(nibName: nil, bundle: nil)
        self.coordinator = coordinator
        self.model = BeatModel()
        self.isAddSongsMode = inAddSongsMode
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        refreshSongsAndReloadData(shouldReloadData: true)
    }
    
    // MARK: - Setup
    private func setupUI() {
        songTableView.dataSource = self
        songTableView.delegate = self
        songTableView.register(UITableViewCell.self, forCellReuseIdentifier: "SongCell")
        
        if isAddSongsMode {
            editButton.isHidden = true
            rainbowMusicBanner.isHidden = true
        }
    }
    
    // MARK: - Public Methods
    func refreshSongsAndReloadData(shouldReloadData: Bool) {
        let brandNewSongs = model.getAllSongs()
        songs = brandNewSongs
        if shouldReloadData {
            songTableView.reloadData()
        }
    }
    
    // MARK: - Actions
    @IBAction func editButtonTapped(_ sender: UIButton) {
        if songTableView.isEditing {
            songTableView.setEditing(false, animated: true)
            editButton.setTitle("Edit", for: .normal)
        } else {
            songTableView.setEditing(true, animated: true)
            editButton.setTitle("Done", for: .normal)
        }
    }
}

// MARK: - UITableViewDataSource
extension HomeViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = songTableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath)
        let beat = songs[indexPath.row]
        cell.textLabel?.text = beat.title
        
        if currentlyPlayingSongTitle == beat.title {
            let nowPlayingView = UILabel(frame: CGRect(x: 0, y: 0, width: 120, height: cell.frame.size.height))
            nowPlayingView.text = "Now Playing"
            nowPlayingView.textColor = .gray
            
            let labelHolder = UIView(frame: nowPlayingView.frame)
            labelHolder.backgroundColor = .clear
            labelHolder.addSubview(nowPlayingView)
            cell.accessoryView = labelHolder
        } else {
            cell.accessoryView = nil
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath.row != destinationIndexPath.row {
            let beatToMove = songs[sourceIndexPath.row]
            songs.remove(at: sourceIndexPath.row)
            songs.insert(beatToMove, at: destinationIndexPath.row)
        }
    }
}

// MARK: - UITableViewDelegate
extension HomeViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isAddSongsMode {
            coordinator?.addSongToQueue(songs[indexPath.row])
            return
        }
        
        let beat = songs[indexPath.row]
        if currentlyPlayingSongTitle == beat.title {
            coordinator?.openPlayerWithoutSong()
        } else {
            // This range encompasses the song we just selected and every song after it
            let queueRange = NSRange(location: indexPath.row, length: songs.count - indexPath.row)
            let indexes = IndexSet(integersIn: queueRange)
            let songsForQueue = Array(songs[indexes])
            coordinator?.openPlayerWithSongs(songsForQueue)
            rowSelected = true
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let selectedBeat = songs[indexPath.row]
            model.deleteSong(selectedBeat)
            refreshSongsAndReloadData(shouldReloadData: false)
            
            let indexPaths = [indexPath]
            tableView.deleteRows(at: indexPaths, with: .fade)
        }
    }
}

// MARK: - PlayerDelegate
extension HomeViewController: PlayerDelegate {
    
    func currentItemDidChangeStatus(_ status: AVPlayerItem.Status) {
        // Do nothing
    }
    
    func didUpdateCurrentProgressTo(_ fractionCompleted: Double) {
        // Do nothing
    }
    
    func playerDidChangeSongTitle(_ songTitle: String) {
        // Update the correct table view cell with the title
        currentlyPlayingSongTitle = songTitle
        songTableView.reloadData()
    }
    
    func playerDidChangeState(_ state: PlayerState) {
        // Do nothing
    }
    
    func requestProgressBarUpdate() {
        // Do nothing
    }
    
    func requestTableViewUpdate() {
        // Do nothing
    }
    
    func selectedIndexesChanged(_ count: Int) {
        // Do nothing
    }
}
