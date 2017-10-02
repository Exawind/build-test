Please refer to the official [Nalu documentation](http://nalu.readthedocs.io/en/latest) regarding building and testing Nalu.

### NaluSpack v1.2.0 Release Notes

Note the testing script in this release has been modified to snapshot Nalu v1.2.0 along with Spack, and the TPLs used at the time of the v1.2.0 release, giving an entire snapshot of how Nalu v1.2.0 was being built at the time of release. Therefore checking out this release of NaluSpack should give a clear way to build Nalu as it existed at the time of the v1.2.0 release by use of the `test_nalu.sh` script.

This release coincides with the release of Trilinos 12.12.1 and the beginning of the second year of work in the ECP.

Major TPLs typically used for Nalu v1.2.0 are:
* Trilinos v12.12.1
* HDF5 v1.8.16
* NetCDF v4.3.3.1
* PnetCDF v1.6.1
* OpenMPI v1.10.4
* Boost v1.60.0
* SuperLU v4.3
* CMake v3.6.1
* Netlib Lapack 3.6.1
* YAML-CPP v0.5.3
* LibXML2 v2.9.4

Compilers typically used for Nalu v1.2.0 are:
* GCC 4.9.2
* GCC 5.2.0
* Intel 17.0.2

Notable matching tags useful for NaluSpack v1.2.0 are:
* Nalu v1.2.0
* Spack commit d3e4e88bae2b3ddf71bf56da18fe510e74e020b2
