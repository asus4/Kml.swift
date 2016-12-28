//
//  ViewController.swift
//  Kml
//
//  Created by Koki Ibukuro on 8/17/15.
//  Copyright (c) 2015 asus4. All rights reserved.
//

import UIKit
import CoreLocation

class MainViewController: UITableViewController {

    let locationManager = CLLocationManager()
    let dataSource: [(label: String, klass: UIViewController.Type, nib: String)] = [
        ("Placemark", PlacemarkViewController.self, "PlacemarkViewController"),
        ("Path", PathViewController.self, "PathViewController"),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
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
