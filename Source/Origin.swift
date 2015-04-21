//
//  Origin.swift
//  FeedlyKit
//
//  Created by Hiroki Kumamoto on 1/18/15.
//  Copyright (c) 2015 Hiroki Kumamoto. All rights reserved.
//

import SwiftyJSON

public class Origin: ParameterEncodable {
    public var streamId: String!
    public var title:    String!
    public var htmlUrl:  String!

    public init?(json: JSON) {
        if json == nil { return nil }
        self.streamId = json["streamId"].stringValue
        self.title    = json["title"].stringValue
        self.htmlUrl  = json["htmlUrl"].stringValue
    }
    func toParameters() -> [String : AnyObject] {
        return ["title": title, "htmlUrl": htmlUrl]
    }
}