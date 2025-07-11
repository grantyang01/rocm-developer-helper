0. A good general starting point is the official rocSOLVER documentation, which can be found in the following link: https://rocm.docs.amd.com/projects/rocSOLVER/en/latest/index.html

 

1. The code is open source and can be found in the public repository: https://github.com/ROCm/rocSOLVER/tree/develop.

            - Under `library/src/lapack` and `library/src/auxiliary` you will find all source files for most functions, kernels, etc.

            - Under `library/src/specialized` there is source code for kernels specialized to small sizes.

            - .cpp files contain the C wrappers for the public API.

            - .hpp files contain the `\_template()` methods which are the main entry point to the different algorithms. 

 

2. In particular, you can find in the following links the code for

            - the non-blocked tridiagonalization (sytd2) https://github.com/ROCm/rocSOLVER/blob/develop/library/src/lapack/roclapack_sytd2_hetd2.hpp

            - the generation of Householder transformations (larfg) https://github.com/ROCm/rocSOLVER/blob/develop/library/src/auxiliary/rocauxiliary_larfg.hpp

            - the blocked tridiagonalization (sytrd) https://github.com/ROCm/rocSOLVER/blob/develop/library/src/lapack/roclapack_sytrd_hetrd.hpp

            - the tridiagonalization of a panel (latrd) https://github.com/ROCm/rocSOLVER/blob/develop/library/src/auxiliary/rocauxiliary_latrd.hpp

            - the general eigensolver with divide and conquer (syevd) https://github.com/ROCm/rocSOLVER/blob/develop/library/src/lapack/roclapack_syevd_heevd.hpp

            - the actual divide and conquer for a tridiagonal matrix (stedc) https://github.com/ROCm/rocSOLVER/blob/develop/library/src/auxiliary/rocauxiliary_stedc.hpp

            - the final vector updates (ormtr) https://github.com/ROCm/rocSOLVER/blob/develop/library/src/auxiliary/rocauxiliary_ormtr_unmtr.hpp

            - If you want to look at the preliminary code that we developed for the 2-stages tridiagonal reduction, please contact us.

 

3. If you want/need to build and test rocSOLVER with docker, the easiest way is to use Julio's scripts to setup your docker container https://github.com/jmachado-amd/docker-scripts-preview/tree/main/rocm6.4.2-ubuntu22.04-dev, which are also attached to this message (as rocm6.4.2-ubuntu22.04-dev.tgz)

            - run `./docker-build.sh` to build an image based on ROCm6.4.2 with all requirements

            - run `./docker-run.sh` to start a container for that image

            - run `./docker-exec.sh` to open a terminal in the container

            - See the `README.md` in the repo for more info.

 

4. To build rocSOLVER from source (within the docker container or baremetal):

            - first clone the develop branch: `git clone --single-branch --branch develop https://github.com/ROCm/rocSOLVER.git`

            - Inside the rocSOLVER directory you will find the `install.sh` script, which is the easiest way to build/install the library.

            - run `./install.sh -cn -a gfx942` to build the library and its clients for MI300

            - If you are missing any dependencies (especially when running outside the docker), you can try `./install.sh -cdn -a gfx942`. This will also install any missing dependency (you only need to use `-d` once).

            - run `./install.sh --help` for more installation options.

            - If you want to re-compile after modifying a few files, you can go to `/rocSOLVER/build/release` and run `make`, e.g., `make -j$(nproc)` will run `make` using all CPU threads.

 

5. In `rocsolver/build/release/clients/staging` you will find the executables for the `rocsolver-test` and `rocsolver-bench` clients.

            - use `./rocsolver-test --gtest_filter=*SYEVD*` to run the unit tests for SYEVD, for example.

            - use `./rocsolver-bench -f syevd -n 20 --evect V --iters 10 --perf 1 -r s` to benchmark SYEVD with a 20-by-20 matrix, and compute eigenvectors in single precision. This will return the average time of 10 runs in microseconds.

            - run `./rocsolver-bench --help` to get more information on other options.

            - All tests and benchmarks are executed with random input matrices. The random number generator is seeded for repeatability purposes.

            - If you need/want to run extended or expert tests with more control such as the ones depicted in the appendix of the slides' deck, please contact us for more info.

            - Attached is a simple script (`perf_n_evect`) that you can use to gather perf numbers for different sizes such as the ones we use in the charts we presented.

 

6. If you prefer to run/test rocsolver from within your own application, then use it as any other C API library. You can find some sample codes to start here: https://github.com/ROCm/rocSOLVER/tree/develop/clients/samples
