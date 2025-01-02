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
