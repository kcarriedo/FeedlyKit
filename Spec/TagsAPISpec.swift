//
//  TagsAPISpec.swift
//  FeedlyKit
//
//  Created by Hiroki Kumamoto on 3/12/16.
//  Copyright © 2016 Hiroki Kumamoto. All rights reserved.
//

import Foundation
import FeedlyKit
import Quick
import Nimble

class TagsAPISpec: CloudAPISpec {
    let tagLabel = NSUUID().uuidString
    
    func fetchTags(callback: @escaping (Int, [Tag]) -> ()) {
        let _ = self.client.fetchTags {
            guard let code = $0.response?.statusCode,
                  let tags = $0.result.value else { return }
            callback(code, tags.filter { !$0.id.contains("tag/global.") })
        }
    }

    func createTag(callback: @escaping ([String]) -> ()) {
        let _ = fetchProfile() {
            self.fetchLatestEntries() { entries in
                entries[0].tags = [Tag(label: self.tagLabel, profile: self.profile!)]
                let _ = self.client.createEntry(entries[0]) {
                    guard let ids = $0.result.value else { return }
                    callback(ids)
                }
            }
        }
    }

    override func spec() {
        beforeSuite {
            self.client.setAccessToken(SpecHelper.accessToken)
        }

        describe("fetchTags") {
            if SpecHelper.accessToken == nil { return }
            var statusCode = 0
            var tags: [Tag]? = nil
            beforeEach {
                self.createTag() {_ in 
                    self.fetchTags {
                        statusCode = $0
                        tags = $1
                    }
                }
            }
            it("fetches tags") {
                expect(statusCode).toFinally(equal(200))
                expect(tags).toFinallyNot(beNil())
                expect(tags?.count).to(beGreaterThan(0))
            }
        }

        describe("tagEntry") {
            if SpecHelper.accessToken == nil { return }
            var statusCode = 0
            var entry: Entry?
            var entries: [Entry]?
            beforeEach {
                self.fetchLatestEntries { _entries in
                    let tag = self.profile!.tag(self.tagLabel).id
                    entry = _entries[0]
                    let _ = self.client.tagEntry([tag], entryId: entry!.id) {
                        guard let code = $0.response?.statusCode else { return }
                        statusCode = code
                        let _ = self.client.fetchContents(tag, paginationParams: PaginationParams()) {
                            entries = $0.result.value?.items
                        }
                    }
                }
            }
            it("tag a entry") {
                expect(statusCode).toFinally(equal(200))
                expect(entry).toFinallyNot(beNil())
                expect(entries).toFinallyNot(beNil())
                expect(entries!.map { $0.title! } ).to(contain(entry!.title!))
            }
        }

        describe("tagEntries") {
            if SpecHelper.accessToken == nil { return }
            var statusCode = 0
            var tags: [Tag] = []
            var entryIds: [String]?
            var entries: [Entry]? = nil
            beforeEach {
                self.fetchLatestEntries { _entries in
                    entries = _entries
                    self.fetchTags { code, _tags in
                        if _tags.count == 0 { return }
                        tags = _tags
                        let _ = self.client.tagEntries(_tags.map { $0.id }, entryIds: entries!.map { $0.id }) {
                            guard let code = $0.response?.statusCode else { return }
                            statusCode = code
                            let _ = self.client.fetchEntryIds(tags[0].id, paginationParams: PaginationParams()) {
                                entryIds = $0.result.value?.ids
                            }
                        }
                    }
                }
            }
            it("tag entries") {
                expect(statusCode).toFinally(equal(200))
                expect(entryIds).toFinallyNot(beNil())
                expect(entries).toFinallyNot(beNil())
                for en in entries! {
                    expect(entryIds).to(contain(en.id))
                }
            }
        }

        describe("changeTagLabel") {
            if SpecHelper.accessToken == nil { return }
            var statusCode = 0
            var tags: [Tag]? = nil
            let label = "changed_test"
            beforeEach {
                self.fetchTags { code, _tags in
                    let _ = self.client.changeTagLabel(_tags[0].id, label: label) {
                        guard let code = $0.response?.statusCode else { return }
                        statusCode = code
                        self.fetchTags {
                            tags = $1
                        }
                    }
                }
            }
            it("chnages a label of tag") {
                expect(statusCode).toFinally(equal(200))
                expect(tags).toFinallyNot(beNil())
                expect(tags!.map { $0.label }).to(contain(label))
            }
        }
    
        describe("untagEntries") {
            if SpecHelper.accessToken == nil { return }
            var statusCode = 0
            var tags: [Tag] = []
            var entryIds: [String]?
            var entries: [Entry]?
            beforeEach {
                self.fetchLatestEntries { _entries in
                    entries = _entries
                    self.fetchTags { code, _tags in
                        if _tags.count == 0 { return }
                        tags = _tags.filter { !$0.id.contains("global") }
                        let _ = self.client.untagEntries(tags.map { $0.id }, entryIds: entries!.map { $0.id }) {
                            guard let code = $0.response?.statusCode else { return }
                            statusCode = code
                            let _ = self.client.fetchEntryIds(tags[0].id, paginationParams: PaginationParams()) {
                                entryIds = $0.result.value?.ids
                            }
                        }
                    }
                }
            }
            it("untag entries") {
                expect(statusCode).toFinally(equal(200))
                expect(entryIds).toFinallyNot(beNil())
                for en in entries! {
                    expect(entryIds).notTo(contain(en.id))
                }
            }
        }
    
        describe("deleteTags") {
            if SpecHelper.accessToken == nil { return }
            var statusCode = 0
            var before: [Tag]? = nil
            var after: [Tag]? = nil
            var finally: [Tag]? = nil
            beforeEach {
                self.fetchTags { code, _tags in
                    before = _tags
                    self.createTag {_ in
                        self.fetchTags { code, _tags in
                            after = _tags
                            let _ = self.client.deleteTags( [self.profile!.tag(self.tagLabel).id]) {
                                guard let code = $0.response?.statusCode else { return }
                                statusCode = code
                                self.fetchTags {
                                    finally = $1
                                }
                            }
                        }
                    }
                }
            }
            it("fetches tags") {
                expect(statusCode).toFinally(equal(200))
                expect(before).toFinallyNot(beNil())
                expect(finally).toFinallyNot(beNil())
                expect(after!.count).to(equal(before!.count + 1))
                expect(finally!.count).to(equal(before!.count))
            }

        }
    }
}
