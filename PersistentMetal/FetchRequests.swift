//
//  FetchRequests.swift
//  PersistentMetal
//
//  Created by Lantua on 9/21/2560 BE.
//  Copyright © 2560 Lantua. All rights reserved.
//

import CoreData

public class FetchRequestHelper {
    public static func computations(using buffer: Buffer) -> NSFetchRequest<NSManagedObject> {
        return model.fetchRequestFromTemplate(withName: "ComputationUsingBuffer", substitutionVariables: ["BUFFER" : buffer]) as! NSFetchRequest<NSManagedObject>
    }
    public static func computations(using texture: Texture) -> NSFetchRequest<NSManagedObject> {
        return model.fetchRequestFromTemplate(withName: "ComputationUsingTexture", substitutionVariables: ["TEXTURE": texture]) as! NSFetchRequest<NSManagedObject>
    }
    public static func computations(using function: FunctionID) -> NSFetchRequest<NSManagedObject> {
        return model.fetchRequestFromTemplate(withName: "ComputationUsingFunction", substitutionVariables: ["VALUE": function]) as! NSFetchRequest<NSManagedObject>
    }
    
    public static func buffers(ofLength length: Int32) -> NSFetchRequest<NSManagedObject> {
        return model.fetchRequestFromTemplate(withName: "BufferByLength", substitutionVariables: ["LENGTH": length]) as! NSFetchRequest<NSManagedObject>
    }
    public static func textures(ofType type: MTLTextureType) -> NSFetchRequest<NSManagedObject> {
        return model.fetchRequestFromTemplate(withName: "TextureByType", substitutionVariables: ["TYPE": Int64(type.rawValue)]) as!NSFetchRequest<NSManagedObject>
    }
}

public extension NSManagedObjectContext {
    func fetchBuffer(group: String, name: String) throws -> Buffer? {
        let fetchRequest = model.fetchRequestFromTemplate(withName: "BufferByName", substitutionVariables: ["GROUP": group, "NAME": name])! as! NSFetchRequest<Buffer>
        return try fetch(fetchRequest).first
    }
    func fetchTexture(group: String, name: String) throws -> Texture? {
        let fetchRequest = model.fetchRequestFromTemplate(withName: "TextureByName", substitutionVariables: ["GROUP": group, "NAME": name])! as! NSFetchRequest<Texture>
        return try fetch(fetchRequest).first
    }
}
public extension NSManagedObjectContext {
    func functionCount(of group: String) throws -> Int {
        let fetchRequest = model.fetchRequestFromTemplate(withName: "FunctionOfGroup", substitutionVariables: ["Group": group])!
        fetchRequest.predicate = NSPredicate(format: "group == %@", group)
        return try count(for: fetchRequest)
    }
}
extension NSManagedObjectContext {
    func fetchComputations(group: String) throws -> [Computation] {
        let fetchRequest = model.fetchRequestFromTemplate(withName: "ComputationGroup", substitutionVariables: ["GROUP": group]) as! NSFetchRequest<Computation>
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "order", ascending: true) ]
        fetchRequest.relationshipKeyPathsForPrefetching = ["functionID", "textureEntries.texture", "bufferEntries.buffer"]
        return try fetch(fetchRequest)
    }
}
