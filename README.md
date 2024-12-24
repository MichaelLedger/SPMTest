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

## Remaining issues

[cocoapods-spm](https://github.com/trinhngocthuyen/cocoapods-spm) hook after `running post integrate hooks`, so there may exists two same spm depencies in `Pods.xcodeproj`.

App extension & main project should **manully** add spm depencies & add spm library/framework in `Link Binary With Libraries` to avoid `no such module` issue.
