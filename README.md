Some notes are here, but please refer to the official [Nalu-Wind documentation](http://nalu-wind.readthedocs.io/en/latest) regarding building and testing Nalu-Wind.

### Notes on this repo:

In general, to start with a clean slate, clone Spack, clone this repo, add `SPACK_ROOT` and Spack shell support to your `~/.bash_profile`, source `~/.bash_profile`, then go to the `configs` directory and run `setup-spack.sh` to automatically copy over a recommended Spack configuration for your machine, assuming it's in the list, or study the `setup-spack.sh` script to create your own Spack configuration for your machine. Then look around at the install scripts and testing scripts to learn more about how Nalu is currently being installed and tested.

### Notes on the Nalu-Wind nightly testing:

The file, `test-nalu-wind.sh`, is used for testing on all machines, and the machine name is passed into the script to be able to perform certain required machine-specific tasks.

Then there are cron scripts provided for each machine which run the test job on the machine.

The cron scripts for Mac are plist files which are added to a schedule on OSX by moving the plist file to `/Library/LaunchDaemons` and using `sudo launchctl load -w /Library/LaunchDaemons/com.test.nalu.wind.nightly.plist` and `sudo launchctl list | grep nalu` to see that the launchd job was added.

Lastly, there is a script used for updating this build-test repo each night before running the tests so that changes to what is being tested can propagate to all the machines without doing so manually.
