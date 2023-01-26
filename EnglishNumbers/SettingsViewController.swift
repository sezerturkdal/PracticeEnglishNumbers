//
//  SettingsViewController.swift
//  EnglishNumbers
//
//  Created by Sezer on 22.11.2022.
//

import UIKit
import SwiftRangeSlider

class SettingsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
 
    @IBOutlet weak var chkSound: UISwitch!
    @IBOutlet weak var chkVibration: UISwitch!
    @IBOutlet weak var pckRange: UIPickerView!
    
    var pickerData: [String] =  ["1 - 10", "1 - 100", "1 - 1000"]
    var selectedLevel = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pckRange.delegate = self
        self.pckRange.dataSource = self
        
        setDefaultValues()
        
        self.chkSound.addTarget(self, action: #selector(self.switch_Changed(_:)), for: .valueChanged)
        self.chkVibration.addTarget(self, action: #selector(self.switch_Changed(_:)), for: .valueChanged)
    }
    
    func setDefaultValues(){
        if let IsSoundOn = UserDefaults.standard.string(forKey: "IsSoundOn"){
            let _sound = NSString(string: IsSoundOn)
            chkSound.isOn = _sound.boolValue
        }
        if let IsVibrationOn = UserDefaults.standard.string(forKey: "IsVibrationOn"){
            let _vibration = NSString(string: IsVibrationOn)
            chkVibration.isOn = _vibration.boolValue
        }
        if let SelectedRange = UserDefaults.standard.string(forKey: "SelectedRange"){
            let _range = NSString(string: SelectedRange)
            pckRange.selectRow(_range.integerValue, inComponent: 0, animated: true)
        }
    }
    
    @objc private func switch_Changed(_ switch: UISwitch) {
        UserDefaults.standard.set(chkSound.isOn, forKey: "IsSoundOn")
        UserDefaults.standard.set(chkVibration.isOn, forKey: "IsVibrationOn")
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return pickerData.count
        }else{
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return pickerData[row]
        }else{
            return ""
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedLevel = pickerView.selectedRow(inComponent: 0)
        UserDefaults.standard.set(pckRange.selectedRow(inComponent: 0), forKey: "SelectedRange")
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return pickerView.frame.size.width
    }
}
