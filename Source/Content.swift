//
//  Content.swift
//  FeedlyKit
//
//  Created by Hiroki Kumamoto on 1/18/15.
//  Copyright (c) 2015 Hiroki Kumamoto. All rights reserved.
//

import SwiftyJSON

public class Content: ParameterEncodable {
    public var direction: String!
    public var content: String!

    public init?(json: JSON) {
        if json == nil { return nil }
        self.direction = json["direction"].stringValue
        self.content   = json["content"].stringValue
    }

    func toParameters() -> [String : AnyObject] {
        return ["direction": direction,
                  "content": content]
    }
}
