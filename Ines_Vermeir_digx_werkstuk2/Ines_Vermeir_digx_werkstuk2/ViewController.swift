//
//  ViewController.swift
//  Ines_Vermeir_digx_werkstuk2
//
//  Created by VERMEIR Inès (s) on 02/06/2018.
//  Copyright © 2018 VERMEIR Inès (s). All rights reserved.
//

import UIKit
import Foundation
import CoreData

class ViewController: UIViewController{

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        getData()
        
        
        
        
        
    }
    
    
    func getData(){
    
        let url = URL(string: "https://api.jcdecaux.com/vls/v1/stations?apiKey=6d5071ed0d0b3b68462ad73df43fd9e5479b03d6&contract=Bruxelles-Capitale")
        let urlRequest = URLRequest(url: url!)
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        session.dataTask(with: urlRequest){
            (data, response, error) in
            guard error == nil else {
                print("Error calling GET")
                print(error!)
                return
            }
            guard let responseData = data
            else {
                print("Error: no data")
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [[String: AnyObject]] {
                    DispatchQueue.main.async {
                        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                        let managedContext = appDelegate.persistentContainer.viewContext
                        for station in json {
                            let id = station["number"] as? Int16
                            let name = station["name"] as? String
                            let address = station["address"] as? String
                            let status = station["status"] as? String
                            let available_bike_stands = station["available_bike_stands"] as? Int16
                            let available_bikes = station["available_bikes"] as? Int16
                            let position = station["position"]!
                            let lat = position["lat"] as? Double
                            let lng = position["lng"] as? Double
                            if let station = NSEntityDescription.insertNewObject(forEntityName: "VilloStation", into: managedContext) as? VilloStation {
                                station.id = id!
                                station.name = name!
                                station.address = address!
                                station.status = status!
                                station.available_bikes = available_bikes!
                                station.available_bike_stands = available_bike_stands!
                                station.lat = lat!
                                station.lng = lng!
                            }
                        }
                        do {
                            try managedContext.save()
                        }catch {
                            fatalError("could not save")
                        }
                    }
                }
            } catch let error {
                print(error)
            }
        }.resume()
        
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

