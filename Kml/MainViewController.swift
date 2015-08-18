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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension MainViewController: UITableViewDataSource {

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier("Sample") as? UITableViewCell {
            cell.textLabel?.text = dataSource[indexPath.row].label
            return cell
        }
        return UITableViewCell()
    }
}

extension MainViewController: UITableViewDelegate {
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let klass = dataSource[indexPath.row].klass
        let nibName = dataSource[indexPath.row].nib
        let controller: UIViewController = klass(nibName: nibName, bundle: nil)
        controller.title = dataSource[indexPath.row].label
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
