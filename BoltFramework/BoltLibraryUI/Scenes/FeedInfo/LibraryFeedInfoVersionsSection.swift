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

import Combine
import SwiftUI

import BoltDocsets
import BoltTypes
import BoltUIFoundation

private final class LibraryFeedInfoVersionsSectionModel: ObservableObject {

  struct FeedEntryListModel: Identifiable {
    enum InstallableStatus {
      case latest
      case installed
      case updateAvailable(currentVersion: String)
      case installable
    }

    let feedEntry: FeedEntry
    let installableStatus: InstallableStatus

    var id: String {
      return feedEntry.id
    }
  }

  private var cancellables = Set<AnyCancellable>()
  private let activityStatusTracker = ActivityStatusTracker<[FeedEntryListModel], Error>()

  @Published var refreshTrigger: Void = ()
  @Published var statusResult: ActivityStatus<[FeedEntryListModel], Error> = .idle

  private(set) var feed: Feed

  init(feed: Feed) {
    self.feed = feed

    let fetchEntriesPublisher: () -> Future<[FeedEntry], Error> = {
      return Future<[FeedEntry], Error>.awaitingThrowing {
        return try await feed.fetchEntries()
      }
    }

    let handleRefreshing: () -> AnyPublisher<Result<[FeedEntryListModel], Error>, Never> = {
      return Publishers.CombineLatest(
        fetchEntriesPublisher(),
        LibraryDocsetsManager.shared.installedRecords()
          .setFailureType(to: Error.self)
      )
      .map { feedEntries, records -> [FeedEntryListModel] in
        return feedEntries.map { entry -> FeedEntryListModel in
          var installableStatus: FeedEntryListModel.InstallableStatus = .installable
          for record in records {
            guard record.name == entry.feed.id else {
              continue
            }
            if record.installedAsLatestVersion, entry.isTrackedAsLatest {
              if record.version == entry.version {
                installableStatus = .latest
              } else {
                installableStatus = .updateAvailable(currentVersion: record.version)
              }
            } else if record.version == entry.version {
              installableStatus = .installed
            }
          }
          return FeedEntryListModel(feedEntry: entry, installableStatus: installableStatus)
        }
      }
      .eraseToAnyPublisher()
      .mapToResult()
    }

    $refreshTrigger
      .flatMap { _ in handleRefreshing() }
      .trackActivityStatus(activityStatusTracker)
      .sink { result in
        if case let .failure(error) = result {
          Task { @MainActor in
            GlobalUI.showMessageToast(
              withErrorMessage: ErrorMessage(entity: ErrorMessageEntity.fetchEntriesFailed, nestedError: error)
            )
          }
        }
      }
      .store(in: &cancellables)

    activityStatusTracker
      .status
      .assign(to: &$statusResult)
  }

}

private struct FeedInfoStaticListItem: View {

  private var title: String
  private var subtitle: String?
  private var indicatorSymbolName: String?

  init(title: String, subtitle: String? = nil, indicatorSymbolName: String? = nil) {
    self.title = title
    self.subtitle = subtitle
    self.indicatorSymbolName = indicatorSymbolName
  }

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
        if let subtitle = subtitle {
          Text(subtitle)
            .foregroundColor(.secondary)
            .font(.system(.caption))
        }
      }
      Spacer()
      if let indicatorSymbolName = indicatorSymbolName {
        Text(Image(systemName: indicatorSymbolName))
      }
    }
  }

}

struct LibraryFeedInfoVersionsSection: View {

  private typealias ViewModel = LibraryFeedInfoVersionsSectionModel

  @StateObject private var viewModel: ViewModel

  @State private var showsAllVersions = false

  init(feed: Feed) {
    _viewModel = StateObject(wrappedValue: { ViewModel(feed: feed) }())
  }

  private func buildVersionsListItem(entryListModel: ViewModel.FeedEntryListModel) -> AnyView {
    let entry = entryListModel.feedEntry
    let shouldShowVersionedItem = !viewModel.feed.shouldHideVersions && showsAllVersions
    if shouldShowVersionedItem || entry.isTrackedAsLatest {
      switch entryListModel.installableStatus {
      case .installable:
        return AnyView(
          NavigationLink(
            destination: DeferredView { LibraryFeedEntryView(entry) }
          ) {
            // versions for docsets marked 'latest' should be hidden to the user
            DownloadProgressListItemView(
              identifier: entry.id,
              title: entry.isTrackedAsLatest ? "Latest" : entry.version,
              subtitle: nil, // (!entry.feed.shouldHideVersions && entry.isTrackedAsLatest) ? entry.version : nil,
              preventsHighlight: true
            )
          }
        )
      case let .updateAvailable(currentVersion):
        assert(entry.isTrackedAsLatest)
        return AnyView(
          NavigationLink(
            destination: DeferredView { LibraryFeedEntryView(entry) }
          ) {
            let subtitle = viewModel.feed.shouldHideVersions
              ? "Update Available:"
              : "Update Available: \(entry.version) / \(currentVersion)"
            DownloadProgressListItemView(
              identifier: entry.id,
              title: "Latest",
              subtitle: subtitle,
              preventsHighlight: true
            )
          }
        )
      case .installed:
        assert(!entry.isTrackedAsLatest)
        return AnyView(
          FeedInfoStaticListItem(
            title: entry.version,
            subtitle: nil,
            indicatorSymbolName: "checkmark.circle"
          )
        )
      case .latest:
        assert(entry.isTrackedAsLatest)
        return AnyView(
          FeedInfoStaticListItem(
            title: "Latest",
            subtitle: "Up to date",
            indicatorSymbolName: "checkmark.circle"
          )
        )
      }
    }
    return AnyView(EmptyView())
  }

  var body: some View {
    Section(header: Text("Versions")) {
      if case .result(let result) = viewModel.statusResult {
        if case .success(let allVersions) = result {
          if !viewModel.feed.shouldHideVersions {
            BoltToggle("Show All Available Versions", isOn: $showsAllVersions)
          }
          ForEach(allVersions) { entry in
            buildVersionsListItem(entryListModel: entry)
          }
        } else {
          Button("Retry") {
            viewModel.refreshTrigger = ()
          }
        }
      } else {
        HStack(spacing: 8) {
          ProgressView()
          Text("Loading Versions…")
        }
      }
    }
  }

}
