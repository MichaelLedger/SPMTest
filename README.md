# SPMTest
Swift Package Manager Test Library.

## Environments
MacOS 15.2
Xcode 16.2

## Practice
Use Xcode to open `Package.swift`.

## [Linking the package only in debug builds](https://augmentedcode.io/2022/05/02/linking-a-swift-package-only-in-debug-builds/)
App target’s libraries.Then we’ll open build settings and look for “Excluded Source File Names” and configure release builds to ignore “[LookinServer*](https://github.com/QMUI/LookinServer)”.

Build settings configured to ignore the package in release builds.To verify this change, we can make a release build with shift+command+i (Product -> Build For -> Profiling which builds release configuration). If we check the latest build log with command+9 and clicking on the top most build item, scrolling to app target’s linker step, we can see that Xcode did not link “LookinServer”. Exactly what we wanted to achieve.

// Podfile
`pod 'LookinServer',    '1.2.6',    :configurations => ['Debug']`

// Build Settings -> Excluded Source File Names 
`"EXCLUDED_SOURCE_FILE_NAMES[arch=*]" = "LookinServer*";`

## [Is it okay to have both SPM and Cocoapods in your project?](https://www.reddit.com/r/iOSProgramming/comments/16dvujc/is_it_okay_to_have_both_spm_and_cocoapods_in_your/)

No one's mentioned this, but yes, it can work, as long as the dependencies on each side have independent trees.

**That is, all of the CocoaPods dependencies should be separate from all the SPM dependencies. Otherwise you're going to get duplicate symbol errors or other build issues.**

At best you'd increase your app size with duplicate libraries.

## SPM mixed with CocoaPods

[cocoapods-spm](https://github.com/trinhngocthuyen/cocoapods-spm)

This plugin will auto add swift packages to `Pods.xcodeproj` for spm_pkg in `Podfile`.

**NOTE: you may manully add the same swift package in your main project if this package is used in main project.**
 
// Gemfile

`gem "cocoapods-spm", '~>0.1.9'`

Run `bundle install`

// Podfile
```
  spm_pkg 'SDWebImage',
  :url => "git@github.com:SDWebImage/SDWebImage.git",
  :version => "5.20.0",
  :products => ["SDWebImage-SPM"]
  
  spm_pkg 'SDWebImageWebPCoder',
  :url => "git@github.com:SDWebImage/SDWebImageWebPCoder.git",
  :version => "0.14.6",
  :products => ["SDWebImageWebPCoder-SPM"]
  
  pod 'XXXKit1', :git => "git@github.com:organization/XXXKit1.git", :branch => "Feature-SPM-001"
  pod 'XXXKit2', '~> 8.22.0'
  pod 'XXXKit3', :path => '../../XXXKit3'
```

Assume `XXXKit1`,`XXXKit2`,`XXXKit3` depends on `SDWebImage` & `YYYKit1`,`YYYKit2` depends on `SnapKit`.

## [Using a post_install script to add SPM reps to cocoa pods targets to resolve no such module issues](https://github.com/CocoaPods/CocoaPods/issues/10049#issuecomment-819480131)
```
  post_integrate do |installer|
    add_spms_to_targets(installer)
    //other hooks...
  end

  def add_spm_to_target(project, target_name, url, requirement, product_name)
    project.targets.each do |target|
      if target.name == target_name
        pkg = project.root_object.package_references.find { |pkg| pkg.repositoryURL == url }
        if pkg.nil?
          pkg = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
          pkg.repositoryURL = url
          pkg.requirement = requirement
          project.root_object.package_references << pkg
          puts "=====new swift package reference==#{pkg.repositoryURL}"
        else
          puts "=====matched swift package reference==#{pkg.repositoryURL}"
        end
        ref = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
        ref.package = pkg
        ref.product_name = product_name
        target.package_product_dependencies << ref
      end
    end
    project.save
  end
  
  # add spm to pod targets
  # spm dependency rules: (upToNextMajorVersion/ upToNextMinorVersion / exactVersion / versionRange)
  # Xcode will crash when setting duplicate spm dependencies with the same rule, so we set rule as `upToNextMajorVersion` for now.
  def add_spms_to_targets(installer)
    spm_specs = [{
      url: "git@github.com:SDWebImage/SDWebImage.git",
      requirement: {
        kind: "upToNextMajorVersion",
        minimumVersion: "5.20.0"
      },
      product_name: "SDWebImage",
      targets: ["XXXKit1", "XXXKit2", "XXXKit2"]
    },{
      url: "git@github.com:SnapKit/SnapKit.git",
      requirement: {
        kind: "upToNextMajorVersion",
        minimumVersion: "5.0.1"
      },
      product_name: "SnapKit",
      targets: ["YYYKit1", "YYYKit2"]
    }]
    spm_specs.each do | spm_spec |
      spm_spec[:targets].each do |target_name|
        puts "=====add_spm==#{spm_spec[:product_name]}==to_target==#{target_name}"
        add_spm_to_target(installer.pods_project,
                          target_name,
                          spm_spec[:url],
                          spm_spec[:requirement],
                          spm_spec[:product_name])
      end
    end
  end

```

Run before build project:

**NOTE: Before running `pod install`, keep main project opened by Xcode, causing package dependencies loaded from cache or remote.**

`bundle exec pod install --no-repo-update --verbose`

##  Build service could not create build operation: unknown error while handling message: MsgHandlingError(message: "unable to initiate PIF transfer session (operation in progress?)")

relaunch Xcode to refetch the remote package dependencies.

## Using Forward Declarations to resolve circular-import-error: Module 'BraintreeCore' not found

If spm module is not found, first check `Link Binary With Libraries`; then if import codes exists in C Header, there must exists circular import error.

Causing by specific Objective-C header imported spm swift module && Bridging Header imported this specific Objective-C header.

This problem has been bothering me all day to location. 

(reset package dependency -> relink library -> check framework/header search paths -> test Demo from braintree -> check target build phases shells)

Resolution: [Include Swift Classes in Objective-C Headers Using Forward Declarations](https://developer.apple.com/documentation/swift/importing-swift-into-objective-c)

```
//@import BraintreeCore;
//@import BraintreeLocalPayment;
//@import BraintreeSEPADirectDebit;
//@import BraintreeCard;
//@import BraintreeApplePay;
//@import BraintreePayPal;

@protocol BTLocalPaymentRequestDelegate, BTThreeDSecureRequestDelegate;
@class BTLocalPaymentRequest, BTSEPADirectDebitRequest, BTAPIClient, BTSEPADirectDebitClient, BTLocalPaymentClient, BTPayPalClient, BTThreeDSecureClient;
```

## Remaining issues

### Issue 1. two same spm depencies in `Pods.xcodeproj`
[cocoapods-spm](https://github.com/trinhngocthuyen/cocoapods-spm) hook after `running post integrate hooks`, so there may exists two same spm depencies in `Pods.xcodeproj`.

App extension & main project should **manully** add spm depencies & add spm library/framework in `Link Binary With Libraries` to avoid `no such module` issue.

### Issue 2. `pod lib lint` or `pod repo push` fails if replacing `dependency` with `spm_dependency` even install cocoapods-spm plugin.

`$ pod repo push mine_specs 'XXX.podspec' --sources='https://cdn.cocoapods.org/,git@github.com:XXX/mine_specs.git' --allow-warnings --skip-import-validation --skip-tests --verbose --local-only`

```
[!] Invalid `XXXKit.podspec` file: undefined method `spm_dependency' for an instance of Pod::Specification.

 #  from /Users/gavinxiang/Downloads/XXX/XXX.podspec:94
 #  -------------------------------------------
 #    s.dependency "Moya", "~> 15.0.0"
 >    s.spm_dependency "SnapKit", "~> 5.0.1"
 #    s.dependency "RxSwift", "~> 6.0.0"
 #  -------------------------------------------

[!] The `XXX.podspec` specification does not validate.
```
**We can only manually push `.podspec` or using feature branch to install pods for now. **

Fixed pod repo push failed while downloading dependencies & generating pods project in Gemfile:

`gem "cocoapods-spm2", '~>0.1.20'`

```
$ cat Gemfile
source "https://rubygems.org"

ruby "3.3.5"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem "cocoapods"
gem "fastlane"
gem 'fastools', :git => 'git@github.com:MichaelLedger/fastools.git', :branch => 'master'
gem "cocoapods-spm2", '~>0.1.20'
```

but still cannot find moudle

```
    - ERROR | xcodebuild:  XXXCustomDesignView.swift:9:8: error: no such module 'SDWebImage'
[!] The `XXXKit.podspec` specification does not validate.

/Users/gavinxiang/.rbenv/versions/3.3.5/lib/ruby/gems/3.3.0/gems/cocoapods-1.15.2/lib/cocoapods/command/repo/push.rb:156:in `block in validate_podspec_files'
```

because `plugin "cocoapods-spm"` is not in Podfile while lint. [cocoapods-spm2](https://github.com/MichaelLedger/cocoapods-spm.git)

[Cocoapod: how to push spec to my private repo without lint?](https://stackoverflow.com/questions/33206886/cocoapod-how-to-push-spec-to-my-private-repo-without-lint)

```
$ vim /Users/gavinxiang/.rbenv/versions/3.3.5/lib/ruby/gems/3.3.0/gems/cocoapods-1.15.2/lib/cocoapods/command/repo/push.rb
```

**force disable `validate_podspec_files` in `run` method in cocoapods `push.rb` works!**:
```
        def run
          open_editor if @commit_message && @message.nil?
          check_if_push_allowed
          update_sources if @update_sources
          #validate_podspec_files # This is disabled because it is not needed for SPM
          check_repo_status
          update_repo
          add_specs_to_repo
          push_repo unless @local_only
        end

```
```
$ bundle exec pod repo push mine_repos 'XXXKit.podspec' --sources='https://cdn.cocoapods.org/,git@github2.com:MichaelLedger/Specs.git' --allow-warnings --skip-import-validation --skip-tests --verbose --local-only

Updating the `mine_repos' repo

  $ /usr/bin/git -C /Users/gavinxiang/.cocoapods/repos/mine_repos pull
  Already up to date.

Adding the spec to the `mine_repos' repo

  $ /usr/bin/git -C /Users/gavinxiang/.cocoapods/repos/mine_repos status --porcelain
  ?? XXXKit/0.1.62/
 - [Update] XXXKit (0.1.62)
  $ /usr/bin/git -C /Users/gavinxiang/.cocoapods/repos/mine_repos add XXXKit
  $ /usr/bin/git -C /Users/gavinxiang/.cocoapods/repos/mine_repos commit --no-verify -m [Update] XXXKit (0.1.62)
  [master bd16046] [Update] XXXKit (0.1.62)
   1 file changed, 146 insertions(+)
   create mode 100644 XXXKit/0.1.62/XXXKit.podspec
```

### Issue3: adding plugin `cocoapods-spm` in Podfile before generating pods project.

[iOS] script_phases: Invalid execution position value `before_generate_project` in shell script `Configure Test Environment`. 

Available options are `before_compile, after_compile, before_headers, after_headers, any`.

```
// .podspec
# ――― Test Configurations ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files  = "Source/Classes/Address/*.swift", "Source/Classes/Account/*.swift", "Source/Classes/Foundation/*.swift",
    test_spec.exclude_files = "Classes/Exclude"

    # Specify plugins in the test environment
    test_spec.script_phase = {
      # :name => 'Configure Test Environment',
      # :script => 'echo "plugin \'cocoapods-spm\'" >> ${PODS_ROOT}/Podfile',
      # :execution_position => :before_compile

      :name => 'Add Plugins to Podfile',
      :script => '<<-SCRIPT
        PODFILE="${PODS_ROOT}/Podfile"
        if ! grep -q "plugin \'cocoapods-spm\'" "$PODFILE"; then
          # Create temp file
          tmp_file=$(mktemp)
          # Add plugin at the top
          echo "plugin \'cocoapods-spm\'" > "$tmp_file"
          # Append original Podfile content
          cat "$PODFILE" >> "$tmp_file"
          # Replace original file
          mv "$tmp_file" "$PODFILE"
        fi
      SCRIPT',
      :execution_position => :before_headers
    }
  end
```

`Adding Build Phase '[CP-User] Add Plugins to Podfile' to project.` is too later!

```
Comparing resolved specification to the sandbox manifest
  A Alamofire
  A Clarity
  A Moya
  A XXXKit
  A PRTBaseLog
  A PRTBaseTracker
  A RxCocoa
  A RxRelay
  A RxSwift
  A SwiftyBeaver

Resolving SPM dependencies
The following packages were not declared in Podfile:
  • SnapKit: used by XXXKit
  • SDWebImage: used by XXXKit
Use the `spm_pkg` method to declare those packages in Podfile.

Downloading dependencies
...

Integrating target `Clarity`
    Adding Build Phase '[CP] Copy XCFrameworks' to project.

Integrating target `XXXKit`
    Adding Build Phase '[CP] Embed Pods Frameworks' to project.
    Adding Build Phase '[CP] Copy Pods Resources' to project.
    Adding Build Phase '[CP-User] Add Plugins to Podfile' to project.
  - Stabilizing target UUIDs
  - Running post install hooks
  - Writing Xcode project file to `../../../../private/var/folders/wk/frkkcch539lc6s2dk6dw9dy80000gn/T/CocoaPods-Lint-20241230-99199-5dt736-XXXKit/Pods/Pods.xcodeproj`
  Cleaning up sandbox directory

Integrating client project

[!] Please close any current Xcode sessions and use `App.xcworkspace` for this project from now on.
```

In addition to the `post_install` hook function, there is another hook function in cocoapods, `pre_install`, which allows us to do something after the pod library has been downloaded but not installed, and the `post_install` hook function allows us to do something before the project is written to the hard disk.

```
# pre_install hook that removes unwanted localizations
pre_install do |installer|
    supported_locales = ['base', 'da', 'en']

    Dir.glob(File.join(installer.sandbox.pod_dir('FormatterKit'), '**', '*.lproj')).each do |bundle|
        if (!supported_locales.include?(File.basename(bundle, ".lproj").downcase))
            puts "Removing #{bundle}"
            FileUtils.rm_rf(bundle)
        end
    end
end
```

### Issue4: [critical cross-dependency bug](https://github.com/swiftlang/swift-package-manager/issues/4581)

Note: There is a critical cross-dependency bug affecting many projects including [RxSwift](https://github.com/ReactiveX/RxSwift?tab=readme-ov-file) in Swift Package Manager. We've filed a bug (SR-12303) in early 2020 but have no answer yet. Your mileage may vary. A partial workaround can be found [here](https://github.com/ReactiveX/RxSwift/issues/2127#issuecomment-717830502).

**For my project it work great. In build settings for main app in chapter build options I change `Enable Testing Search Path` from `NO` to `YES`. I think, that is allow to find path to XCTest framework and use necessary symbol.**

```
// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name: "RxProject",
  dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.0.0"))
  ],
  targets: [
    .target(name: "RxProject", dependencies: ["RxSwift", .product(name: "RxCocoa", package: "RxSwift")]),
  ]
)
```

### Issue5: Compile is passed but archive failed with module not find in some cocoapods libraray generating process.

```
[0m/Volumes/ExDisk/Jenkins-workspace/FPA-000-SPM-Mix-CocoaPods-Feature/FreePrints/Pods/XXXSDK/LoginViewModel.swift:9:8: [31mno such module 'RxRelay'[0m
```

You can manullay add lost module in pod target's target dependencies to resolve this archive error. (e.g. add `RxRelay` in XXXSDK's `target dependencies`)

It's hard to add dependency via shell command because `pod install` will reset all `target dependencies`.

## Practice
### Could use different tags to distinguish between cocoapods and spm.

[GoogleUtilities - 8.0.2](https://github.com/google/GoogleUtilities/releases/tag/8.0.2)

[GoogleUtilities - CocoaPods-8.0.2](https://github.com/google/GoogleUtilities/releases/tag/CocoaPods-8.0.2)

- Swift Package Manager

By creating and pushing a tag for Swift PM, the newly tagged version will be immediately released for public use. Given this, please verify the intended time of release for Swift PM.

Add a version tag for Swift PM
```
git tag {version}
git push origin {version}
```
Note: Ensure that any inflight PRs that depend on the new GoogleUtilities version are updated to point to the newly tagged version rather than a checksum.

- CocoaPods

Publish the newly versioned pod to CocoaPods

It's recommended to point to the GoogleUtilities.podspec in staging to make sure the correct spec is being published.

`pod trunk push ~/.cocoapods/repos/staging/GoogleUtilities/{version}/GoogleUtilities.podspec.json`

Note: In some cases, it may be acceptable to `pod trunk push` with the `--skip-tests` flag. Please double check with the maintainers before doing so.

The pod push was successful if the above command logs: 🚀  GoogleUtilities ({version}) successfully published. In addition, a new commit that publishes the new version (co-authored by CocoaPodsAtGoogle) should appear in the CocoaPods specs repo. Last, the latest version should be displayed on GoogleUtilities's CocoaPods page.

### Integrate multiple libraries into the same package

[braintree_ios/Package.swift](https://github.com/braintree/braintree_ios/blob/main/Package.swift)

```
// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Braintree",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "BraintreeAmericanExpress",
            targets: ["BraintreeAmericanExpress"]
        ),
        .library(
            name: "BraintreeApplePay",
            targets: ["BraintreeApplePay"]
        ),
        .library(
            name: "BraintreeCard",
            targets: ["BraintreeCard"]
        ),
        .library(
            name: "BraintreeCore",
            targets: ["BraintreeCore"]
        ),
        .library(
            name: "BraintreeDataCollector",
            targets: ["BraintreeDataCollector", "PPRiskMagnes"]
        ),
        .library(
            name: "BraintreeLocalPayment",
            targets: ["BraintreeLocalPayment", "PPRiskMagnes"]
        ),
        .library(
            name: "BraintreePayPal",
            targets: ["BraintreePayPal", "PPRiskMagnes"]
        ),
        .library(
            name: "BraintreePayPalMessaging",
            targets: ["BraintreePayPalMessaging"]
        ),
        .library(
            name: "BraintreePayPalNativeCheckout",
            targets: ["BraintreePayPalNativeCheckout"]
        ),
        .library(
            name: "BraintreeSEPADirectDebit",
            targets: ["BraintreeSEPADirectDebit"]
        ),
        .library(
            name: "BraintreeShopperInsights",
            targets: ["BraintreeShopperInsights"]
        ),
        .library(
            name: "BraintreeThreeDSecure",
            targets: ["BraintreeThreeDSecure", "CardinalMobile", "PPRiskMagnes"]
        ),
        .library(
            name: "BraintreeVenmo",
            targets: ["BraintreeVenmo"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "BraintreeAmericanExpress",
            dependencies: ["BraintreeCore"],
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "BraintreeApplePay",
            dependencies: ["BraintreeCore"],
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "BraintreeCard",
            dependencies: ["BraintreeCore"],
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "BraintreeCore",
            exclude: ["Info.plist", "Braintree.h"],
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "BraintreeDataCollector",
            dependencies: ["BraintreeCore", "PPRiskMagnes"],
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "BraintreeLocalPayment",
            dependencies: ["BraintreeCore", "BraintreeDataCollector"],
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "BraintreePayPal",
            dependencies: ["BraintreeCore", "BraintreeDataCollector"],
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "BraintreePayPalMessaging",
            dependencies: ["BraintreeCore", "PayPalMessages"],
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .binaryTarget(
            name: "PayPalMessages",
            url: "https://github.com/paypal/paypal-messages-ios/releases/download/1.0.0/PayPalMessages.xcframework.zip",
            checksum: "565ab72a3ab75169e41685b16e43268a39e24217a12a641155961d8b10ffe1b4"
        ),
        .target(
            name: "BraintreePayPalNativeCheckout",
            dependencies: ["BraintreeCore", "BraintreePayPal", "PayPalCheckout"],
            path: "Sources/BraintreePayPalNativeCheckout",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .binaryTarget(
            name: "PayPalCheckout",
            url: "https://github.com/paypal/paypalcheckout-ios/releases/download/1.3.0/PayPalCheckout.xcframework.zip",
            checksum: "d65186f38f390cb9ae0431ecacf726774f7f89f5474c48244a07d17b248aa035"
        ),
        .target(
            name: "BraintreeSEPADirectDebit",
            dependencies: ["BraintreeCore"],
            path: "Sources/BraintreeSEPADirectDebit",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "BraintreeShopperInsights",
            dependencies: ["BraintreeCore"],
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "BraintreeThreeDSecure",
            dependencies: ["BraintreeCard", "CardinalMobile", "PPRiskMagnes", "BraintreeCore"],
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .binaryTarget(
            name: "CardinalMobile",
            path: "Frameworks/XCFrameworks/CardinalMobile.xcframework"
        ),
        .target(
            name: "BraintreeVenmo",
            dependencies: ["BraintreeCore"],
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .binaryTarget(
            name: "PPRiskMagnes",
            path: "Frameworks/XCFrameworks/PPRiskMagnes.xcframework"
        )
    ]
)
```

[RxSwift/Package.swift](https://github.com/ReactiveX/RxSwift/blob/main/Package.swift)
```
// swift-tools-version:5.5

import PackageDescription

let buildTests = false

extension Product {
  static func allTests() -> [Product] {
    if buildTests {
      return [.executable(name: "AllTestz", targets: ["AllTestz"])]
    } else {
      return []
    }
  }
}

extension Target {
    static func rxTarget(name: String, dependencies: [Target.Dependency]) -> Target {
        .target(
            name: name,
            dependencies: dependencies,
            resources: [.copy("PrivacyInfo.xcprivacy")]
        )
    }
}

extension Target {
  static func rxCocoa() -> [Target] {
    #if os(Linux)
      return [.rxTarget(name: "RxCocoa", dependencies: ["RxSwift", "RxRelay"])]
    #else
      return [.rxTarget(name: "RxCocoa", dependencies: ["RxSwift", "RxRelay", "RxCocoaRuntime"])]
    #endif
  }

  static func rxCocoaRuntime() -> [Target] {
    #if os(Linux)
      return []
    #else
      return [.rxTarget(name: "RxCocoaRuntime", dependencies: ["RxSwift"])]
    #endif
  }

  static func allTests() -> [Target] {
    if buildTests {
      return [.target(name: "AllTestz", dependencies: ["RxSwift", "RxCocoa", "RxBlocking", "RxTest"])]
    } else {
      return []
    }
  }
}

let package = Package(
  name: "RxSwift",
  platforms: [.iOS(.v9), .macOS(.v10_10), .watchOS(.v3), .tvOS(.v9)],
  products: ([
    [
      .library(name: "RxSwift", targets: ["RxSwift"]),
      .library(name: "RxCocoa", targets: ["RxCocoa"]),
      .library(name: "RxRelay", targets: ["RxRelay"]),
      .library(name: "RxBlocking", targets: ["RxBlocking"]),
      .library(name: "RxTest", targets: ["RxTest"]),
      .library(name: "RxSwift-Dynamic", type: .dynamic, targets: ["RxSwift"]),
      .library(name: "RxCocoa-Dynamic", type: .dynamic, targets: ["RxCocoa"]),
      .library(name: "RxRelay-Dynamic", type: .dynamic, targets: ["RxRelay"]),
      .library(name: "RxBlocking-Dynamic", type: .dynamic, targets: ["RxBlocking"]),
      .library(name: "RxTest-Dynamic", type: .dynamic, targets: ["RxTest"]),
    ],
    Product.allTests()
  ] as [[Product]]).flatMap { $0 },
  targets: ([
    [
      .rxTarget(name: "RxSwift", dependencies: []),
    ],
    Target.rxCocoa(),
    Target.rxCocoaRuntime(),
    [
      .rxTarget(name: "RxRelay", dependencies: ["RxSwift"]),
      .target(name: "RxBlocking", dependencies: ["RxSwift"]),
      .target(name: "RxTest", dependencies: ["RxSwift"]),
    ],
    Target.allTests()
  ] as [[Target]]).flatMap { $0 },
  swiftLanguageVersions: [.v5]
)
```

### [`library(name:type:targets:)`](https://developer.apple.com/documentation/packagedescription/product/library(name:type:targets:))

> A library’s product can be either statically or dynamically linked. It’s recommended that you don’t explicitly declare the type of library, so Swift Package Manager can choose between static or dynamic linking based on the preference of the package’s consumer.

### [Understanding Static Library vs Dynamic Library in iOS Swift](https://medium.com/takodigital/understanding-static-library-vs-dynamic-library-in-ios-swift-f675f603a050)

Understanding the differences between static libraries and dynamic libraries is essential for iOS Swift developers.

**Static libraries provide simplicity, performance, and code protection, while dynamic libraries offer code sharing, versioning flexibility, and dynamic loading capabilities.**

By choosing the appropriate type of library based on your project’s requirements, you can optimize your development process and create efficient, scalable iOS applications.

### Try add swift package library to pod target's target denpendecies

[lib/xcodeproj/project/object/native_target.rb](https://github.com/CocoaPods/Xcodeproj/blob/master/lib/xcodeproj/project/object/native_target.rb)

```
# Add Target Dependency
#        container_proxy = Xcodeproj::Project::Object::PBXContainerItemProxy.new(
#          {
#            container_portal: project.root_object.uuid,
#            proxy_type: 1, # 1 for target, 2 for project
#            remote_global_id_string: pkg.uuid,
#            remote_info: product_name
#          }
#        )
#        container_proxy = Xcodeproj::Project::Object::PBXContainerItemProxy.new(
#          project.root_object.uuid, # container_portal
#          pkg.uuid # remote_global_id_string
#        )
        container_proxy = project.new(Xcodeproj::Project::PBXContainerItemProxy)
        container_proxy.container_portal = project.root_object.uuid
        container_proxy.proxy_type = "1"
        container_proxy.remote_global_id_string = ref.uuid
        container_proxy.remote_info = ref.product_name
        puts "=====container_proxy==#{container_proxy}"
#        target_dependency = Xcodeproj::Project::Object::PBXTargetDependency.new(
#          product_name,
#          container_proxy
#        )
        target_dependency = project.new(Xcodeproj::Project::PBXTargetDependency)
        target_dependency.name = ref.product_name
#        target_dependency.target = target if target.project == project
        target_dependency.target_proxy = container_proxy
        puts "=====target_dependency==#{target_dependency}"
        puts "=====add_target_dependency==#{product_name}==to_target==#{target_name}"
        target.dependencies << target_dependency
```

```
[!] An error occurred while processing the post-integrate hook of the Podfile.

undefined method `name' for an instance of Xcodeproj::Project::Object::XCRemoteSwiftPackageReference

/Users/gavinxiang/.rbenv/versions/3.3.5/lib/ruby/gems/3.3.0/gems/xcodeproj-1.27.0/lib/xcodeproj/project/object/native_target.rb:254:in `add_dependency'
```

pkg or ref has no `name` method and xcodeproj faileds to load!!!
