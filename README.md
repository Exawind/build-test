Some notes are here, but please refer to the official [Nalu documentation](http://nalu.readthedocs.io/en/latest) regarding building and testing Nalu.

### Notes on this repo:

In general, to start with a clean slate, clone Spack, clone this repo, add `SPACK_ROOT` and Spack shell support to your `~/.bash_profile`, source `~/.bash_profile`, then go to the `configs` directory and run `setup_spack.sh` to automatically copy over a recommended Spack configuration for your machine, assuming it's in the list, or study the `setup_spack.sh` script to create your own Spack configuration for your machine. Then look around at the install scripts and testing scripts to learn more about how Nalu is currently being installed and tested. Note the `shared_constraints.sh` script that is sourced which sets the preferred TPLs for Nalu and preferred Trilinos options.

### Notes on the Nalu nightly testing:

The file, `test_nalu.sh`, is used for testing on all machines, and the machine name is passed into the script to be able to perform certain required machine-specific tasks.

Then there are cron scripts provided for each machine which `qsub` the test job. Note on Peregrine, `qsub` cannot pass arguments to the script itself (`man qsub` says the `-F` parameter should do so, but it doesn't work), so another script is provided that does only the task of passing `peregrine` to `test_nalu.sh`.

The cron scripts for Mac are actually plist files which are added to a schedule on OSX by moving the plist file to `/Library/LaunchDaemons` and using `sudo launchctl load -w /Library/LaunchDaemons/com.test.nalu.nightly.plist` and `sudo launchctl list | grep nalu` to see that the launchd job was added.

Lastly, there is a script used for updating this NaluSpack repo each night before running the tests so that changes to what is being tested can propagate to all the machines without doing so manually.

Using crontab, the general cron jobs are written as such:
```
SHELL=/bin/bash

#Nalu update NaluSpack
0 0 * * * /bin/bash -c "cd /whereever/NaluNightlyTesting/NaluSpack && ./test_scripts/update_naluspack.sh > /whereever/NaluNightlyTesting/jobs/last_naluspack_update.txt 2>&1"
#Nalu tests
0 1 * * * /whereever/NaluNightlyTesting/NaluSpack/test_scripts/test_nalu_peregrine_cron.sh > /whereever/NaluNightlyTesting/jobs/last_nalu_test_job.txt 2>&1
```
