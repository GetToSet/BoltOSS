//
// Copyright (C) 2023 Bolt Contributors
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

import Factory

import BoltNetworkingTestStubs
import BoltTestingUtils

class RepositoryTestCase: BaseTestCase {

  override func setUp() {
    super.setUp()
    Container.shared.manager.push()
    Container.shared.reset(options: .all)
    Container.shared.repositoryModuleInitializer()()
  }

  override func tearDown() {
    super.tearDown()
    Container.shared.manager.pop()
  }

}
