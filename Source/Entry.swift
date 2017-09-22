//
//  Entry.swift
//  MusicFav
//
//  Created by Hiroki Kumamoto on 12/23/14.
//  Copyright (c) 2014 Hiroki Kumamoto. All rights reserved.
//

import Foundation
import SwiftyJSON

public final class Entry: Equatable, Hashable,
                          ResponseObjectSerializable, ResponseCollectionSerializable,
                          ParameterEncodable {
    public var id:              String
    public var title:           String?
    public var content:         Content?
    public var summary:         Content?
    public var author:          String?
    public var crawled:         Int64 = 0
    public var recrawled:       Int64 = 0
    public var published:       Int64 = 0
    public var updated:         Int64?
    public var alternate:       [Link]?
    public var origin:          Origin?
    public var keywords:        [String]?
    public var visual:          Visual?
    public var unread:          Bool = true
    public var tags:            [Tag]?
    public var categories:      [Category] = []
    public var engagement:      Int?
    public var actionTimestamp: Int64?
    public var enclosure:       [Link]?
    public var fingerprint:     String?
    public var originId:        String?
    public var sid:             String?

    public class func collection(_ response: HTTPURLResponse, representation: Any) -> [Entry]? {
        let json = JSON(representation)
        return json.arrayValue.map({ Entry(json: $0) })
    }

    @objc required public convenience init?(response: HTTPURLResponse, representation: Any) {
        let json = JSON(representation)
        self.init(json: json)
    }

    public static var instanceDidInitialize: ((Entry, JSON) -> Void)?

    public init(id: String) {
        self.id = id
    }

    public init(json: JSON) {
        self.id              = json["id"].stringValue
        self.title           = json["title"].string
        self.content         = Content(json: json["content"])
        self.summary         = Content(json: json["summary"])
        self.author          = json["author"].string
        self.crawled         = json["crawled"].int64Value
        self.recrawled       = json["recrawled"].int64Value
        self.published       = json["published"].int64Value
        self.updated         = json["updated"].int64
        self.origin          = Origin(json: json["origin"])
        self.keywords        = json["keywords"].array?.map({ $0.string! })
        self.visual          = Visual(json: json["visual"])
        self.unread          = json["unread"].boolValue
        self.tags            = json["tags"].array?.map({ Tag(json: $0) })
        self.categories      = json["categories"].arrayValue.map({ Category(json: $0) })
        self.engagement      = json["engagement"].int
        self.actionTimestamp = json["actionTimestamp"].int64
        self.fingerprint     = json["fingerprint"].string
        self.originId        = json["originId"].string
        self.sid             = json["sid"].string
        if let alternates = json["alternate"].array {
            self.alternate   = alternates.map({ Link(json: $0) })
        } else {
            self.alternate   = nil
        }
        if let enclosures = json["enclosure"].array {
            self.enclosure   = enclosures.map({ Link(json: $0) })
        } else {
            self.enclosure   = nil
        }
        Entry.instanceDidInitialize?(self, json)
    }

    public var hashValue: Int {
        return id.hashValue
    }

    public func toParameters() -> [String : Any] {
        var params: [String: Any] = ["published": NSNumber(value: published)]
        if let _title     = title     { params["title"]     = _title as AnyObject? }
        if let _content   = content   { params["content"]   = _content.toParameters() as AnyObject? }
        if let _summary   = summary   { params["summary"]   = _summary.toParameters() as AnyObject? }
        if let _author    = author    { params["author"]    = _author as AnyObject? }
        if let _enclosure = enclosure { params["enclosure"] = _enclosure.map({ $0.toParameters() }) }
        if let _alternate = alternate { params["alternate"] = _alternate.map({ $0.toParameters() }) }
        if let _keywords  = keywords  { params["keywords"]  = _keywords as AnyObject? }
        if let _tags      = tags      { params["tags"]      = _tags.map { $0.toParameters() }}
        if let _origin    = origin    { params["origin"]    = _origin.toParameters() as AnyObject? }

        return params
    }

    public var thumbnailURL: URL? {
        if let v = visual, let url = v.url.toURL() {
            return url
        }
        if let links = enclosure {
            for link in links {
                if let url = link.href.toURL() {
                    if link.type.contains("image") { return url }
                }
            }
        }
        if let url = extractImgSrc() {
            return url
        }
        return nil
    }

    func extractImgSrc() -> URL? {
        if let html = content?.content {
            let regex = try? NSRegularExpression(pattern: "<img.*src\\s*=\\s*[\"\'](.*?)[\"\'].*>",
                options: NSRegularExpression.Options())
            if let r = regex {
                let range = NSRange(location: 0, length: html.characters.count)
                if let result  = r.firstMatch(in: html, options: NSRegularExpression.MatchingOptions(), range: range) {
                    for i in 0...result.numberOfRanges - 1 {
                        let range = result.range(at: i)
                        let str = html as NSString
                        if let url = str.substring(with: range).toURL() {
                            return url
                        }
                    }
                }
            }
        }
        return nil
    }
}

public func == (lhs: Entry, rhs: Entry) -> Bool {
    return lhs.id == rhs.id
}
