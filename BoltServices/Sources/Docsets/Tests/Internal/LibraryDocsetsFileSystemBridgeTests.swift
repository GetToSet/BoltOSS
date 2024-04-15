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

import BoltTypes

final class LibraryDocsetsFileSystemBridgeTests: XCTestCase {

  func testResolveDocsetIcon() throws {
    let installation = DocsetInstallation(
      name: "cpp",
      version: "1.0",
      installedAsLatestVersion: false,
      repository: .main
    )
    let info = DocsetInfoProcessor.docsetInfo(
      forInfoDictionary: [
        DocsetInfoKey.bundleIdentifier.rawValue: "cpp",
        DocsetInfoKey.platformFamily.rawValue: "cpp",
      ]
    )
    XCTAssertEqual(
      LibraryDocsetsFileSystemBridge._docsetIcon(
        fromDocsetPath: "",
        index: installation,
        docsetInfo: info
      ),
      EntryIcon.bundled(name: "docset-icons/cpp")
    )
  }

}
