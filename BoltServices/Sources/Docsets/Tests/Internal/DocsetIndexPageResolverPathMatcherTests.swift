//
// Copyright (C) 2024 Bolt Contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import XCTest

@testable import BoltDocsets

final class DocsetIndexPageResolverPathMatcherTests: XCTestCase {

  func testFindFirstMatchInPaths() {

    var matcher = DocsetIndexPageResolver.PathMatcher(docsetPath: Bundle.module.path(forResource: "TestResources/Vim.docset")!)
    var result = matcher.findFirstMatchInPaths(["builtin.html"])
    XCTAssertEqual(result, "builtin.html")

    matcher = DocsetIndexPageResolver.PathMatcher(docsetPath: Bundle.module.path(forResource: "TestResources/Vim_tarix.docset")!)
    result = matcher.findFirstMatchInPaths(["builtin.html"])
    XCTAssertEqual(result, "builtin.html")
  }

}