//
//  StatusViewController.swift
//  ImageDetection
//
//  Created by GUNNER on 2020/2/20.
//  Copyright © 2020 GUNNER. All rights reserved.
//

import Foundation
import ARKit

class StatusViewController: UIViewController {
    
    enum MessageType {
        case trackingStateEscalation
        case contentPlacement
        
        static var all: [MessageType] = [
            .contentPlacement,
            .trackingStateEscalation
        ]
    }
    
    // MARK: - IBOutlets
    @IBOutlet weak private var messagePanel: UIVisualEffectView!
    
    @IBOutlet weak private var messageLabel: UILabel!
    
    @IBOutlet weak private var restartExperienceButton: UIButton!
    
    // MARK: Properties
    
    // 当“重置体验”按钮被按下后触发
    var restartExperienceHandler: () -> Void = {}
    
    // 计时器消息逐渐消失的时间。如果app需要更长的瞬时消失时，可以调整此值
    private let displayDuartion: TimeInterval = 6
    
    // 用来隐藏消息的计时器
    private var messageHideTimer: Timer?
    
    private var timers: [MessageType: Timer] = [:]
    
    // MARK: - Message Handling
    func showMessage(_ text: String, autoHide: Bool = true) {
        // 取消之前所有隐藏计时器
        messageHideTimer?.invalidate()
        
        messageLabel.text = text
        
        setMessageHidden(false, animated: true)
        
        if autoHide {
            messageHideTimer = Timer.scheduledTimer(withTimeInterval: displayDuartion, repeats: false, block: { [weak self] _ in
                self?.setMessageHidden(true, animated: true)
            })
        }
    }
    
    func scheduleMessage(_ text: String, inSeconds seconds: TimeInterval, messageType: MessageType) {
        cancelScheduledMessage(for: messageType)
        
        let timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: {
            [weak self] timer in self?.showMessage(text)
            timer.invalidate()
        })
        timers[messageType] = timer
    }
    
    func cancelScheduledMessage(for messageType: MessageType) {
        timers[messageType]?.invalidate()
        timers[messageType] = nil
    }
    
    func cancelAllScheduledMessage() {
        for messageType in MessageType.all {
            cancelScheduledMessage(for: messageType)
        }
    }
    
    // MARK: - ARKit
    func showTrackingQualityInfo(for trackingState: ARCamera.TrackingState, autoHide: Bool) {
        showMessage(trackingState.presentationString, autoHide: autoHide)
    }
    
    func esacalteFeedback(for trackingState: ARCamera.TrackingState, inSeconds seconds: TimeInterval) {
        cancelScheduledMessage(for: .trackingStateEscalation)
        
        let timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: {
            [unowned self] _ in self.cancelScheduledMessage(for: .trackingStateEscalation)
            
            var message = trackingState.presentationString
            if let recommendation = trackingState.recommendation {
                message.append(": \(recommendation)")
            }
            
            self.showMessage(message, autoHide: true)
        })
        
        timers[.trackingStateEscalation] = timer
    }
    
    // MARK: IBActions
    @IBAction func restartExperience(_ sender: UIButton) {
        restartExperienceHandler()
    }
    
    
    // MARK: - Panel Visibility
    private func setMessageHidden(_ hide: Bool, animated: Bool) {
        
        // 这个panel开始时是隐藏的，所以用动画效果修改透明度前先将其显示出来
        messagePanel.isHidden = false
        guard animated else {
            messagePanel.alpha = hide ? 0 : 1
            return
        }
        
        UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState], animations: {
            self.messagePanel.alpha = hide ? 0 : 1
        }, completion: nil)
    }
}

extension ARCamera.TrackingState {
    var presentationString: String {
        switch self {
        case .notAvailable:
            return "追踪不可用"
        case .normal:
            return "追踪正常"
        case .limited(.excessiveMotion):
            return "追踪受限\n移动过快"
        case .limited(.insufficientFeatures):
            return "追踪受限\n细节略少"
        case .limited(.initializing):
            return "初始化中"
        case .limited(.relocalizing):
            return "中断恢复中"
        case .limited(_):
            return "追踪受限\n未知问题"
        }
    }

    var recommendation: String? {
        switch self {
        case .limited(.excessiveMotion):
            return "尝试减缓移动速度，或者重置会话"
        case .limited(.insufficientFeatures):
            return "尝试指向平整的表面，或者重置会话"
        case .limited(.relocalizing):
            return "尝试回到中断发生的地方，或者重置会话"
        default:
            return nil
        }
    }
}
