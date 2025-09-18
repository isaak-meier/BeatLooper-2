//
//  Beat+CoreDataProperties.swift
//  
//
//  Created by Isaak Meier on 9/17/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Beat {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Beat> {
        return NSFetchRequest<Beat>(entityName: "Beat")
    }

    @NSManaged public var fileUrl: String?
    @NSManaged public var tempo: Int16
    @NSManaged public var title: String?

}

extension Beat : Identifiable {

}
