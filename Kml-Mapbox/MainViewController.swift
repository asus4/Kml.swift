//
//  ViewController.swift
//  Kml-Mapbox
//
//  Created by Greg Pardo on 12/28/16.
//  Copyright © 2016 asus4. All rights reserved.
//

import UIKit
import Mapbox
import CoreLocation

let MapboxAccessToken = "<# your Mapbox access token #>"

class MainViewController: UITableViewController {
    
    let locationManager = CLLocationManager()
    let dataSource: [(label: String, klass: UIViewController.Type, nib: String)] = [
        ("Placemark", PlacemarkViewController.self, "PlacemarkViewController"),
        ("Path", PathViewController.self, "PathViewController"),
        ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(MapboxAccessToken != "<# your Mapbox access token #>", "You must set `MapboxAccessToken` to your Mapbox access token.")
        MGLAccountManager.setAccessToken(MapboxAccessToken)
        locationManager.requestAlwaysAuthorization()
    }
}

extension MainViewController { // UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "Sample") {
            cell.textLabel?.text = dataSource[(indexPath as NSIndexPath).row].label
            return cell
        }
        return UITableViewCell()
    }
}

extension MainViewController { // UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let klass = dataSource[(indexPath as NSIndexPath).row].klass
        let nibName = dataSource[(indexPath as NSIndexPath).row].nib
        let controller: UIViewController = klass.init(nibName: nibName, bundle: nil)
        controller.title = dataSource[(indexPath as NSIndexPath).row].label
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
