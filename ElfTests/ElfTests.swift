//
//  ElfTests.swift
//  ElfTests
//
//  Created by limboy on 2019/2/2.
//  Copyright © 2019 limboy. All rights reserved.
//

import XCTest
@testable import Elf

class ElfTests: XCTestCase {
    
    func testPlaceHolder() {
        let pattern = "app://foo/{bar}"
        let url = "app://foo/123"
        let (params, _) = Elf.instance.parseParams(url: url, pattern: pattern)
        guard let value = params["bar"] else {
            return XCTAssert(false, "parse placeholder failed")
        }
        XCTAssert(value == "123", "placeholder value not equal")
    }
    
    func testChinesePlaceHolder() {
        let pattern = "app://foo/{bar}"
        let url = "app://foo/中文"
        let (params, _) = Elf.instance.parseParams(url: url, pattern: pattern)
        guard let value = params["bar"] else {
            return XCTAssert(false, "parse placeholder failed")
        }
        XCTAssert(value == "中文", "placeholder value not equal")
    }
    
    func testPlaceHolderWithQueryString() {
        let pattern = "app://foo/{bar}"
        let url = "app://foo/123?a=b&c=d"
        let (params, queryParams) = Elf.instance.parseParams(url: url, pattern: pattern)
        guard let value = params["bar"] else {
            return XCTAssert(false, "parse placeholder failed")
        }
        XCTAssert(value == "123", "placeholder value not equal")
        XCTAssert(queryParams["a"]! == "b", "query string not match")
        XCTAssert(queryParams["c"]! == "d", "query string not match")
    }
    
    func testPlaceHolderWithQueryStringEncoded() {
        let pattern = "app://foo/{bar}"
        let url = "app://foo/123?url=http%3A%2F%2Fwww.baidu.com%3Fa%3Db%26c%3Dd"
        let expectedValue = "http://www.baidu.com?a=b&c=d"
        let (params, queryParams) = Elf.instance.parseParams(url: url, pattern: pattern)
        guard let value = params["bar"] else {
            return XCTAssert(false, "parse placeholder failed")
        }
        XCTAssert(value == "123", "placeholder value not equal")
        XCTAssert(queryParams["url"]! == expectedValue, "query string not match")
    }
    
    func testExactlyMatch() {
        class TestHandler:Handler {
            var flag = false
            func convert(params: Dictionary<String, String>, queryParams: Dictionary<String, String>) {
                XCTAssert(params.count == 0, "params should be empty")
                XCTAssert(queryParams.count == 0, "query params should be empty")
                flag = true
            }
            
            func handle() {
                
            }
        }
        let handler = TestHandler()
        let table = ["app://foo/bar": handler]
        Elf.instance.registerRoutingTable(table, notFoundHandler: nil)
        Elf.instance.handleURL(url: "app://foo/bar")
        XCTAssert(handler.flag, "handler not triggered")
    }
    
    func testVariableMatch() {
        class TestHandler:Handler {
            var converted = false
            var handled = false
            func convert(params: Dictionary<String, String>, queryParams: Dictionary<String, String>) {
                XCTAssert(params["foo"]! == "bar", "params should be empty")
                XCTAssert(queryParams["a"]! == "b", "query params should be empty")
                converted = true
            }
            
            func handle() {
                handled = true
            }
        }
        let handler = TestHandler()
        let table = ["app://hello/{foo}": handler]
        Elf.instance.registerRoutingTable(table, notFoundHandler: nil)
        Elf.instance.handleURL(url: "app://hello/bar?a=b")
        XCTAssert(handler.converted, "handler convert not triggered")
        XCTAssert(handler.handled, "handler handle not triggered")
    }
    
    func testVariableVSExactMatch() {
        class VariableHandler:Handler {
            var converted = false
            var handled = false
            func convert(params: Dictionary<String, String>, queryParams: Dictionary<String, String>) {
                converted = true
            }
            
            func handle() {
                handled = true
            }
        }
        
        class ExactHandler:Handler {
            var flag = false
            func convert(params: Dictionary<String, String>, queryParams: Dictionary<String, String>) {
                XCTAssert(params.count == 0, "params should be empty")
                XCTAssert(queryParams.count == 0, "query params should be empty")
                flag = true
            }
            
            func handle() {
                
            }
        }
        
        let variableHandler = VariableHandler()
        let exactHandler = ExactHandler()
        let table:[String:Handler] = ["app://hello/{foo}": variableHandler, "app://hello/world": exactHandler]
        Elf.instance.registerRoutingTable(table, notFoundHandler: nil)
        Elf.instance.handleURL(url: "app://hello/world")
        XCTAssert(!variableHandler.converted, "variable handler convert not triggered")
        XCTAssert(!variableHandler.handled, "variable handler handle not triggered")
        XCTAssert(exactHandler.flag, "exact handler handle not triggered")
    }
    
    func testMatchPriority1() {
        class Variable2Handler:Handler {
            var converted = false
            var handled = false
            func convert(params: Dictionary<String, String>, queryParams: Dictionary<String, String>) {
                converted = true
            }
            
            func handle() {
                handled = true
            }
        }
        
        class Variable1Handler:Handler {
            var converted = false
            var handled = false
            func convert(params: Dictionary<String, String>, queryParams: Dictionary<String, String>) {
                converted = true
            }
            
            func handle() {
                handled = true
            }
        }
        
        class ExactHandler:Handler {
            var flag = false
            func convert(params: Dictionary<String, String>, queryParams: Dictionary<String, String>) {
                XCTAssert(params.count == 0, "params should be empty")
                XCTAssert(queryParams.count == 0, "query params should be empty")
                flag = true
            }
            
            func handle() {
                
            }
        }
        
        let variable1Handler = Variable1Handler()
        let variable2Handler = Variable2Handler()
        let exactHandler = ExactHandler()
        let table:[String:Handler] = [
            "app://hello/{foo}": variable1Handler,
            "app://hello/world/{foo}": variable2Handler,
            "app://hello/world": exactHandler
        ]
        Elf.instance.registerRoutingTable(table, notFoundHandler: nil)
        Elf.instance.handleURL(url: "app://hello/world")
        XCTAssert(!variable1Handler.converted, "variable handler convert not triggered")
        XCTAssert(!variable1Handler.handled, "variable handler handle not triggered")
        XCTAssert(!variable2Handler.converted, "variable handler convert not triggered")
        XCTAssert(!variable2Handler.handled, "variable handler handle not triggered")
        XCTAssert(exactHandler.flag, "exact handler handle not triggered")
    }
    
    func testMatchPriority2() {
        class Variable2Handler:Handler {
            var converted = false
            var handled = false
            func convert(params: Dictionary<String, String>, queryParams: Dictionary<String, String>) {
                converted = true
            }
            
            func handle() {
                handled = true
            }
        }
        
        class Variable1Handler:Handler {
            var converted = false
            var handled = false
            func convert(params: Dictionary<String, String>, queryParams: Dictionary<String, String>) {
                converted = true
            }
            
            func handle() {
                handled = true
            }
        }
        
        class ExactHandler:Handler {
            var flag = false
            func convert(params: Dictionary<String, String>, queryParams: Dictionary<String, String>) {
                XCTAssert(params.count == 0, "params should be empty")
                XCTAssert(queryParams.count == 0, "query params should be empty")
                flag = true
            }
            
            func handle() {
                
            }
        }
        
        let variable1Handler = Variable1Handler()
        let variable2Handler = Variable2Handler()
        let exactHandler = ExactHandler()
        let table:[String:Handler] = [
            "app://hello/{foo}": variable1Handler,
            "app://hello/world/{foo}": variable2Handler,
            "app://hello/world": exactHandler
        ]
        Elf.instance.registerRoutingTable(table, notFoundHandler: nil)
        Elf.instance.handleURL(url: "app://hello/world/yes")
        XCTAssert(!variable1Handler.converted, "variable handler convert not triggered")
        XCTAssert(!variable1Handler.handled, "variable handler handle not triggered")
        XCTAssert(variable2Handler.converted, "variable handler convert not triggered")
        XCTAssert(variable2Handler.handled, "variable handler handle not triggered")
        XCTAssert(!exactHandler.flag, "exact handler handle not triggered")
    }
    
    func testMatchPriority3() {
        class Variable2Handler:Handler {
            var converted = false
            func convert(params: Dictionary<String, String>, queryParams: Dictionary<String, String>) {
                XCTAssert(params["test"]! == "yes", "params not match")
                converted = true
            }
            
            func handle() {
            }
        }
        
        class Variable1Handler:Handler {
            var converted = false
            func convert(params: Dictionary<String, String>, queryParams: Dictionary<String, String>) {
                XCTAssert(queryParams["a"]! == "中文", "params not match")
                converted = true
            }
            
            func handle() {
            }
        }
        
        class ExactHandler:Handler {
            var flag = false
            func convert(params: Dictionary<String, String>, queryParams: Dictionary<String, String>) {
                XCTAssert(params.count == 0, "params should be empty")
                XCTAssert(queryParams.count == 0, "query params should be empty")
                flag = true
            }
            
            func handle() {
                
            }
        }
        
        let variable1Handler = Variable1Handler()
        let variable2Handler = Variable2Handler()
        let exactHandler = ExactHandler()
        let table:[String:Handler] = [
            "app://test/{test}": variable1Handler,
            "app://test/test/{test}": variable2Handler,
            "app://test/test": exactHandler
        ]
        
        Elf.instance.registerRoutingTable(table, notFoundHandler: nil)
        Elf.instance.handleURL(url: "app://test/test")
        XCTAssert(!variable1Handler.converted, "variable handler convert triggered")
        XCTAssert(!variable2Handler.converted, "variable handler convert triggered")
        XCTAssert(exactHandler.flag, "exact handler handle not triggered")
        
        variable1Handler.converted = false
        variable2Handler.converted = false
        exactHandler.flag = false
        Elf.instance.handleURL(url: "app://test/test/yes")
        XCTAssert(!variable1Handler.converted, "variable handler convert triggered")
        XCTAssert(variable2Handler.converted, "variable handler convert not triggered")
        XCTAssert(!exactHandler.flag, "exact handler handle triggered")
        
        variable1Handler.converted = false
        variable2Handler.converted = false
        exactHandler.flag = false
        Elf.instance.handleURL(url: "app://test/yes?a=%E4%B8%AD%E6%96%87")
        XCTAssert(variable1Handler.converted, "variable handler convert not triggered")
        XCTAssert(!variable2Handler.converted, "variable handler convert triggered")
        XCTAssert(!exactHandler.flag, "exact handler handle triggered")
        
    }
    
    func testDifferentScheme() {
        class Scheme1Handler:Handler {
            var converted = false
            func convert(params: Dictionary<String, String>, queryParams: Dictionary<String, String>) {
                XCTAssert(params["name"]! == "world", "params not match")
                converted = true
            }
            
            func handle() {
            }
        }
        
        class Scheme2Handler:Handler {
            var converted = false
            func convert(params: Dictionary<String, String>, queryParams: Dictionary<String, String>) {
                XCTAssert(params["name"]! == "world", "params not match")
                converted = true
            }
            
            func handle() {
            }
        }
        
        let scheme1Handler = Scheme1Handler()
        let scheme2Handler = Scheme2Handler()
        let table:[String:Handler] = ["foo://hello/{name}": scheme1Handler, "bar://hello/{name}": scheme2Handler]
        Elf.instance.registerRoutingTable(table, notFoundHandler: nil)
        Elf.instance.handleURL(url: "bar://hello/world")
        XCTAssert(!scheme1Handler.converted, "scheme1 handler convert triggered")
        XCTAssert(scheme2Handler.converted, "scheme2 handler convert not triggered")
        
        Elf.instance.handleURL(url: "foo://hello/world")
        XCTAssert(scheme1Handler.converted, "scheme1 handler convert triggered")
    }
    
    func testNoScheme() {
        class Scheme1Handler:Handler {
            var converted = false
            func convert(params: Dictionary<String, String>, queryParams: Dictionary<String, String>) {
                converted = true
            }
            
            func handle() {
            }
        }
        
        let scheme1Handler = Scheme1Handler()
        let table:[String:Handler] = ["foo://hello/{name}": scheme1Handler]
        var notFoundHandlerTriggered = false
        Elf.instance.registerRoutingTable(table) {url in notFoundHandlerTriggered = true}
        Elf.instance.handleURL(url: "/hello/world")
        XCTAssert(!scheme1Handler.converted, "scheme1 handler convert triggered")
        XCTAssert(notFoundHandlerTriggered, "not found handler not triggered")
    }
    
    func testNotFoundHandler() {
        var notFoundHandlerTriggered = false
        var notFoundURL = ""
        func notFoundHandler(url: String) {
            notFoundURL = url
            notFoundHandlerTriggered = true
        }
        
        class MyHandler: Handler {
            func convert(params: Dictionary<String, String>, queryParams: Dictionary<String, String>) {
                
            }
            func handle() {
                
            }
        }
        
        let table:[String:Handler] = ["app://notfound": MyHandler()]
        Elf.instance.registerRoutingTable(table, notFoundHandler: notFoundHandler)
        Elf.instance.handleURL(url: "app://foo/bar")
        XCTAssert(notFoundHandlerTriggered, "not found handler not triggered")
        XCTAssert(notFoundURL == "app://foo/bar", "not found url don't match")
    }
}

