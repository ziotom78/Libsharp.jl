# LibSharp

[![Build Status](https://travis-ci.com/ziotom78/LibSharp.jl.svg?branch=master)](https://travis-ci.com/ziotom78/LibSharp.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/ziotom78/LibSharp.jl?svg=true)](https://ci.appveyor.com/project/ziotom78/LibSharp-jl)
[![Codecov](https://codecov.io/gh/ziotom78/LibSharp.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/ziotom78/LibSharp.jl)

This Julia package provides bindings to the libsharp library.

We export the following job types for `sharp_execute!`.
```
SHARP_YtW                   # analysis
SHARP_MAP2ALM = SHARP_YtW   # analysis
SHARP_Y                     # synthesis
SHARP_ALM2MAP = SHARP_Y     # synthesis
SHARP_Yt                    # adjoint synthesis
SHARP_WY                    # adjoint analysis
SHARP_ALM2MAP_DERIV1        # synthesis of first derivatives
```

LibSharp uses its own OpenMP parallelization. Set the environmental variable `OMP_NUM_THREADS` to control the number of threads used.
