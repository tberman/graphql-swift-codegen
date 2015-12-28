#!/usr/bin/rake
require 'pathname'

## [ Constants ] ##############################################################

BIN_NAME = 'graphql-swift-codegen'
DEPENDENCIES = [[:Alamofire, :Alamofire], [:Commander, :Commander], [:ModelMapper, :Mapper]]
CONFIGURATION = 'Release'
BUILD_DIR = 'build/' + CONFIGURATION

## [ Utils ] ##################################################################

def xcpretty(cmd)
  if `which xcpretty` && $?.success?
    sh "set -o pipefail && #{cmd} | xcpretty -c"
  else
    sh cmd
  end
end

def print_info(str)
  (red,clr) = (`tput colors`.chomp.to_i >= 8) ? %W(\e[33m \e[m) : ["", ""]
  puts red, str.chomp, clr
end

def defaults(args)
  bindir = args.bindir.nil? || args.bindir.empty? ? Pathname.new('./build/graphql-swift-codegen/bin')   : Pathname.new(args.bindir)
  fmkdir = args.fmkdir.nil? || args.fmkdir.empty? ? bindir + '../lib'   : Pathname.new(args.fmkdir)
  [bindir, fmkdir]
end

task :check_xcode do
  xcode_dir = `xcode-select -p`.chomp
  xcode_version = `mdls -name kMDItemVersion -raw "#{xcode_dir}"/../..`.chomp
  unless xcode_version.start_with?('7.')
    raise "\n[!!!] You need to use Xcode 7.x to compile SwiftGen. Use xcode-select to change the Xcode used to build from command line.\n\n"
  end
end

## [ Build Tasks ] ############################################################

desc "Build the CLI binary and its frameworks in #{BUILD_DIR}"
task :build, [:bindir] => [:check_xcode] + DEPENDENCIES.map { |fmk, _| fmk } do |_, args|
  (bindir, _) = defaults(args)

  print_info "== Building Binary =="
  frameworks = DEPENDENCIES.map { |_, fmk| "-framework #{fmk}" }.join(" ")
  xcpretty %Q(xcrun -sdk macosx swiftc -O -o #{BUILD_DIR}/#{BIN_NAME} -F #{BUILD_DIR}/ #{frameworks} graphql-swift-codegen/*.swift)
end

DEPENDENCIES.each do |(fmk, _)|
  # desc "Build #{fmk}.framework"
  task fmk do
    print_info "== Building  #{fmk}.framework =="
    xcpretty %Q(xcodebuild -project Pods/Pods.xcodeproj -target #{fmk} -configuration #{CONFIGURATION})
  end
end

desc "Build the CLI and link it so it can be run from #{BUILD_DIR}. Useful for testing without installing."
task :link => :build do
  sh %Q(install_name_tool -add_rpath "@executable_path" #{BUILD_DIR}/#{BIN_NAME})
end

## [ Install Tasks ] ##########################################################

desc "Install the binary in $bindir, frameworks — without the Swift dylibs — in $fmkdir\n" \
     "(defaults $bindir=./swiftgen/bin/, $fmkdir=$bindir/../lib"
task 'install:light', [:bindir, :fmkdir] => :build do |_, args|
  (bindir, fmkdir) = defaults(args)

  print_info "== Installing binary in #{bindir} =="
  sh %Q(mkdir -p "#{bindir}")
  sh %Q(cp -f "#{BUILD_DIR}/#{BIN_NAME}" "#{bindir}")

  print_info "== Installing frameworks in #{fmkdir} =="
  sh %Q(mkdir -p "#{fmkdir}")
  DEPENDENCIES.each do |_, fmk|
    sh %Q(cp -fr "#{BUILD_DIR}/#{fmk}.framework" "#{fmkdir}")
  end
  sh %Q(install_name_tool -add_rpath "@executable_path/#{fmkdir.relative_path_from(bindir)}" "#{bindir}/#{BIN_NAME}")
end

desc "Install the binary in $bindir, frameworks — including Swift dylibs — in $fmkdir\n" \
     "(defaults $bindir=./swiftgen/bin/, $fmkdir=$bindir/../lib"
task :install, [:bindir, :fmkdir] => 'install:light' do |_, args|
  (bindir, fmkdir) = defaults(args)

  print_info "== Linking to standalone Swift dylibs =="
  sh %Q(xcrun swift-stdlib-tool --copy --scan-executable "#{bindir}/#{BIN_NAME}" --platform macosx --destination "#{fmkdir}")
  toolchain_dir = `xcrun -find swift-stdlib-tool`.chomp
  xcode_rpath = File.dirname(File.dirname(toolchain_dir)) + '/lib/swift/macosx'
  sh %Q(xcrun install_name_tool -delete_rpath "#{xcode_rpath}" "#{bindir}/#{BIN_NAME}")
end

## [ Tests & Clean ] ##########################################################

desc "Run the Unit Tests"
task :tests do
  xcpretty %Q(xcodebuild -workspace graphql-swift-codegen.xcworkspace -scheme graphql-swift-codegen -sdk macosx test)
end

desc "Delete the build/ directory"
task :clean do
  sh %Q(rm -fr build)
end

task :default => [:build]
