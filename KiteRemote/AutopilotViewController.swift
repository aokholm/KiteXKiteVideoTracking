//
//  ViewController.swift
//  KiteRemote
//
//  Created by Andreas Okholm on 05/07/16.
//  Copyright © 2016 Andreas Okholm. All rights reserved.
//

import UIKit
import Starscream
import GPUImage
import AVFoundation

class AutopilotViewController: UIViewController {
    
    let network = Network()
    let remote = RemoteBase()
    let kite = Kite()
    var videoProcessing: VideoProcessing!

    var colorThreshold: Float = 0.5

    @IBOutlet weak var colorView: UIView!
    
    @IBOutlet weak var renderView: RenderView!
    @IBOutlet weak var velocity: UILabel!
    @IBOutlet weak var angular: UILabel!

    var kiteKinematicss = [KiteKinematics]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //remote.connect()
        
        // Do any additional setup after loading the view, typically from a nib.
        videoProcessing = VideoProcessing(renderView: renderView, video: false)
        videoProcessing.newPosition = { (position, time) in
            if let kiteKinematics = self.kite.newPosition(position, time: time) {
                self.kiteKinematicss.append(kiteKinematics)
                self.velocity.text = String(format: "%.1f m/s", kiteKinematics.velocity.length)
                self.angular.text = String(format: "%.1f r/s", kiteKinematics.angularVelocity)
            }
            
            self.remote.newPos( Int( (position.x - 0.5) * 1600*0.5 ) )
        }
        
        let tabGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        renderView.addGestureRecognizer(tabGesture)
        let slideGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        renderView.addGestureRecognizer(slideGesture)
        
        videoProcessing.start()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func next(sender: UIButton) {
        if let pagevc = self.parentViewController as? KiteRemotePageViewController {
            pagevc.next(self)
        }
    }

    @IBAction func switchStateChanged(sender: UISwitch) {
        if sender.on {
            videoProcessing.start()
        } else {
            videoProcessing.stop()
            
            network.sendData( kiteKinematicss.map { $0.json } )
            kiteKinematicss.removeAll()
        }
    }
    
    func handleTap(sender: UITapGestureRecognizer) {
        
        if sender.state == .Ended {
            let touchPoint = sender.locationOfTouch(0, inView: renderView)
            
            let normalizedPoint = CGPoint(x: touchPoint.x / renderView.frame.size.width, y: touchPoint.y / renderView.frame.size.height)
            
            videoProcessing.getColorForPoint(normalizedPoint) {
                color in
                print(color)
                self.colorView.backgroundColor = UIColor(CIColor: color)
                self.videoProcessing.setColor(color)
            }
        }
    }
    
    
    func handlePan(sender: UIPanGestureRecognizer) {
        let change = Float(sender.translationInView(renderView).x/100)
        
        if sender.state == .Changed {
            videoProcessing.setThreshold(colorThreshold+change)
        }
        
        if sender.state == .Ended {
            colorThreshold = colorThreshold+change
            videoProcessing.setThreshold(colorThreshold)
        }
    }
    
    
}
