import sys
import os

# Increment the version + build number
# Change scheme to Release
# Build and Analyze
# Notarize the version
# Zip and upload it as a Github release
# Update appcast.xml

def handle_command_execution(command, return_value):
	if return_value != 0:
		print(command + " failed with return value of "+str(return_value))


def increment_build_number():
	# Print the build number. Use the -terse to limit the output to just the buld number
	check_version_command = "agvtool what-version"
	handle_command_execution(check_version_command, os.system(check_version_command))

	# Bump the build number
	bump_version_command = "agvtool next-version -increment-minor-version"
	handle_command_execution(bump_version_command, os.system(bump_version_command))

def increment_version_to(new_version):
	check_version_command = "agvtool new-marketing-version "+new_version
	handle_command_execution(check_version_command, os.system(check_version_command))

def clean_build_analyze_release_config():
	build_command = "xcodebuild -scheme Clocker -project Clocker.xcodeproj/ clean build analyze"
	handle_command_execution(build_command, os.system(build_command))

def test_release_config():
	build_command = "xcodebuild -scheme Clocker -project Clocker.xcodeproj/ test"
	handle_command_execution(build_command, os.system(build_command))

def main():
	if len(sys.argv) < 2:
		print("Doh! Enter the new release version")
		return

	increment_version_to(sys.argv[1])
	increment_build_number()
	clean_build_analyze_release_config()
	test_release_config()

main()