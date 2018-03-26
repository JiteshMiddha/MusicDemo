//
//  ViewController.swift
//  MusicDemo
//
//  Created by Jitesh Middha on 24/03/18.
//  Copyright © 2018 Jitesh Middha. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var playingLabel: UILabel!
    
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var minimumSliderLabel: UILabel!
    
    @IBOutlet weak var maximumSlideLabel: UILabel!
    
    let commandCenter = MPRemoteCommandCenter.shared()
    
    var songs: [MPMediaItem] = []
    var audioPlayer = AVAudioPlayer()
    
    var currentSongIndex = -1
    
    var timer = Timer()
    
    
    
    // MARK: - IBActions
    @IBAction func previousButtonPressed(_ sender: UIButton) {
        
        if self.currentSongIndex > 0 {
            
            self.currentSongIndex = self.currentSongIndex - 1
            let audio = self.songs[self.currentSongIndex]
            
            self.playNewAudio(audio: audio)
        }
    }
    @IBAction func playPauseButtonPressed(_ sender: UIButton) {
        
        guard currentSongIndex != -1 else {
            currentSongIndex = 0
            playNewAudio(audio: songs[currentSongIndex])
            return
        }
        if audioPlayer.isPlaying == true {
            pauseAudio()
        }
        else {
            playAudio()
        }
    }
    
    
    
    
    @IBAction func nextButtonPressed(_ sender: UIButton) {
        
        if self.currentSongIndex < songs.count - 1 {
            
            self.currentSongIndex = self.currentSongIndex + 1
            let audio = self.songs[self.currentSongIndex]
            
            self.playNewAudio(audio: audio)
        }
        
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        
        self.setPlaybackPosition(time: TimeInterval(sender.value))
    }
    
    // MARK: ViewController Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        songs = loadSongs()
        tableView.tableFooterView = UIView()
        tableView.reloadData()
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        commandCenter.previousTrackCommand.isEnabled = (self.currentSongIndex != 0)
        commandCenter.nextTrackCommand.isEnabled = (self.currentSongIndex != self.songs.count - 1)
        
        commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            
            self.pauseAudio()
            return .success
        }
        
        commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            
            self.playAudio()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            if self.currentSongIndex == self.songs.count - 1 {
                // last song
            }
            else {
                self.currentSongIndex = self.currentSongIndex + 1
                let audio = self.songs[self.currentSongIndex]
                
                self.playNewAudio(audio: audio)
                
            }
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            
            if self.currentSongIndex == 0 {
                // first song
            }
            else {
                self.currentSongIndex = self.currentSongIndex - 1
                
                let audio = self.songs[self.currentSongIndex]
                self.playNewAudio(audio: audio)
                
            }
            return .success
        }
        
        
        commandCenter.changePlaybackPositionCommand.addTarget(self, action: #selector(changePlaybackPositionCommand(_:)))
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        tableView.reloadData()
    }
    
    
    // MARK: - Helpers
    
    func playAudio() {
        
        audioPlayer.play()
        self.slider.maximumValue = Float(self.audioPlayer.duration)
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
        playPauseButton.setImage(#imageLiteral(resourceName: "ic_pause"), for: .normal)
    }
    
    func pauseAudio() {
        
        audioPlayer.pause()
        playPauseButton.setImage(#imageLiteral(resourceName: "ic_play_arrow"), for: .normal)
        timer.invalidate()
    }
    
    func playNewAudio(audio: MPMediaItem) {
        
        timer.invalidate()
        
        do {
            try self.audioPlayer = AVAudioPlayer(contentsOf: audio.assetURL!)
            playingLabel.text = audio.title
            self.updateTime(timer)
            let  mediaInfo = [
                
                MPMediaItemPropertyTitle: audio.title ?? "",
                MPMediaItemPropertyArtist: audio.artist ?? "",
                MPMediaItemPropertyPlaybackDuration: audio.playbackDuration,
                MPNowPlayingInfoPropertyPlaybackRate: 1.0,
                MPMediaItemPropertyArtwork: audio.artwork
                ] as [String : Any]
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = mediaInfo
            
            self.playAudio()
            let audioSession = AVAudioSession.sharedInstance()
            
            do {
                try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            }
            catch {
                
            }
            
        }
        catch {
            
        }
        commandCenter.previousTrackCommand.isEnabled = (self.currentSongIndex != 0)
        self.previousButton.isEnabled = (self.currentSongIndex != 0)
        commandCenter.nextTrackCommand.isEnabled = (self.currentSongIndex != self.songs.count - 1)
        self.nextButton.isEnabled = (self.currentSongIndex != self.songs.count - 1)
        self.tableView.reloadData()
    }
    
    func setPlaybackPosition(time: TimeInterval) {
        
        if currentSongIndex != -1 {
            audioPlayer.currentTime = time
        }
    }
    
    @objc func changePlaybackPositionCommand(_ event:MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus{

        self.setPlaybackPosition(time: event.positionTime)
        
        return MPRemoteCommandHandlerStatus.success
    }
    
    @objc func updateTime(_ timer: Timer) {
        
        slider.value = Float(audioPlayer.currentTime)
        minimumSliderLabel.text = stringFromTimeInterval(interval: audioPlayer.currentTime)
        maximumSlideLabel.text = stringFromTimeInterval(interval: audioPlayer.duration)
        
        let infoCenter = MPNowPlayingInfoCenter.default()
        infoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.audioPlayer.currentTime
    }
    
    func stringFromTimeInterval(interval: Double) -> String {
        
        let hours = (Int(interval) / 3600)
        let minutes = Int(interval / 60) - Int(hours * 60)
        let seconds = Int(interval) - (Int(interval / 60) * 60)
        
        if hours != 0 {
            return String.init(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds)
        }
        else {
            return String.init(format: "%0.2d:%0.2d",minutes,seconds)
        }
        
    }
    
    
   
    func loadSongs() -> [MPMediaItem] {
        guard var songs = MPMediaQuery.songs().items else { return [] }
        
        // Sort songs
        songs = songs.sorted(by: {$0.title!.localizedCaseInsensitiveCompare($1.title!) == ComparisonResult.orderedAscending})
        
        return songs
    }
    
}


extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath)
        
        let audio = songs[indexPath.row]
        cell.textLabel?.text = audio.title
        
        if currentSongIndex == indexPath.row {
            cell.imageView?.image = #imageLiteral(resourceName: "ic_play_arrow")
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        }
        else {
            cell.imageView?.image = nil
            cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        currentSongIndex = indexPath.row
        let audio = songs[indexPath.row]
        self.playNewAudio(audio: audio)
    }
    
}
