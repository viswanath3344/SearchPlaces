//
//  PlacesViewController.swift
//  SearchPlaces
//
//  Created by jacob Liu on 09/05/18.
//  Copyright © 2018 8locations. All rights reserved.
//

import UIKit
import Alamofire

class PlacesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    // The sample values
    var values = [""]
    let cellReuseIdentifier = "cell"
    fileprivate var timer: Timer? = nil
    var searchResults = [String]()
    
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    // Using simple subclass to prevent the copy/paste menu
    // This is optional, and a given app may want a standard UITextField
    @IBOutlet weak var textField:UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    // If user changes text, hide the tableView
    @IBAction func textFieldChanged(_ sender: AnyObject) {
        tableView.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        
        tableView.delegate = self
        tableView.dataSource = self
        textField.delegate = self
        
        tableView.isHidden = true
        
        // Manage tableView visibility via TouchDown in textField
         textField.addTarget(self, action: #selector(textFieldTextChanged), for: .editingChanged)
        
     
        
    }
    
    override func viewDidLayoutSubviews()
    {
        // Assumption is we're supporting a small maximum number of entries
        // so will set height constraint to content size
        // Alternatively can set to another size, such as using row heights and setting frame
        heightConstraint.constant = tableView.contentSize.height
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Manage keyboard and tableView visibility
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let touch:UITouch = touches.first else
        {
            return;
        }
        if touch.view != tableView
        {
            textField.endEditing(true)
            tableView.isHidden = true
        }
    }
    
    // Toggle the tableView visibility when click on textField

    @objc func textFieldTextChanged () {
        if textField.hasText
        {
           tableView.isHidden = false
            
            if textField.text!.count > 0
            {
                self.filterPlacesInBackground(textField.text!) { results in
                // Set new items to filter
                
                    self.timer?.invalidate()
                    self.searchResults = results
                    self.timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.typingDidStop), userInfo: self, repeats: false)
                }
            }
            else
            {
                values.removeAll()
                self.tableView.reloadData()
            }
        }
        else
        {
            values.removeAll()
            self.tableView.reloadData()
            tableView.isHidden = true
            
        }
    }
    
    @objc open func typingDidStop() {
        
        
        self.values.removeAll()
        if textField.hasText
        {
         self.values = searchResults
        }
        self.tableView.isHidden = false
        self.tableView.reloadData()
       self.view.layoutIfNeeded()
        
    }
    
    // MARK: UITextFieldDelegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        // TODO: Your app can do something when textField finishes editing
        print("The textField ended editing. Do something based on app requirements.")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return values.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell") as UITableViewCell!
        // Set text from the data model
        cell.textLabel?.text = values[indexPath.row]
        return cell
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Row selected, so set textField to relevant value, hide tableView
        // endEditing can trigger some other action according to requirements
        textField.text = values[indexPath.row]
        tableView.isHidden = true
        textField.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView  =  UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 20))
        let imageView = UIImageView(frame: CGRect(x: tableView.frame.size.width/2-50, y: 0, width: 100, height:20))
        imageView.image = UIImage.init(named: "GoogleImage")
        footerView.addSubview(imageView)
        return footerView
    }
    
    // set height for footer
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
    
    
    fileprivate func filterPlacesInBackground(_ criteria: String, callback: @escaping ((_ results: [String]) -> Void)) {
        //  https://maps.googleapis.com/maps/api/place/autocomplete/json?input=Vict&types=geocode&language=fr&key=YOUR_API_KEY
       let API_Key  = "AIzaSyBH-wWd2bGhPMHRjU7OOp-x8VRA_9zyVh8"
        
        if  let url  =  URL.init(string: "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\(criteria)&key=\(API_Key)")
        {
            
            Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON(completionHandler: {(response:DataResponse<Any>) in
                
                switch(response.result) {
                    
                case .success(_):
                    
                    print(response.result.value ?? "")
                    var results = [String]()
                    
                    if let placesDictionary = response.result.value as? NSDictionary
                    {
                        
                        if (placesDictionary["status"] as! String) == "OK"
                        {
                            if let predictionPlaces  = placesDictionary["predictions"] as? NSArray
                            {
                                for objPlace in predictionPlaces
                                {
                                    if let objPlaceDict = objPlace as? NSDictionary
                                    {
                                        // let objSearchFieldItem  = SearchTextFieldItem.init(title: objPlaceDict["description"] as! String)
                                        
                                        results.append(objPlaceDict["description"] as! String)
                                        
                                    }
                                }
                                DispatchQueue.main.async {
                                    callback(results)
                                }
                            }
                            
                        }
                        else
                        {
                            DispatchQueue.main.async {
                                callback([])
                            }
                        }
                        
                        
                    }
                    
                case .failure(_):
                    DispatchQueue.main.async {
                        callback([])
                    }
                    break
                }
                
                
            });
            callback([])
            
        }
    }
}

