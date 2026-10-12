# brazier-registry

vcpkg registry for the brazier C++ MVC framework.
Provides overlay ports to install brazier modules as vcpkg packages.

## Overview

### Provided ports

| Port | Content | CMake target |
|---|---|---|
| brazier | meta-package: core + orm + logger | brazier::brazier |
| brazier-core | framework core (server, router, HTTP, WebSocket, Engine) | brazier::core |
| brazier-orm | ORM (Model, Database, migrations) | brazier::orm |
| brazier-logger | logging library | brazier::logger |

### Repository layout

```text
 brazier-registry/ 
 ├── ports/ 
 │ ├── brazier/ # meta-package 
 │ ├── brazier-core/ 
 │ ├── brazier-orm/ 
 │ └── brazier-logger/ 
 ├── build.bat # local build (Windows) 
 ├── build.sh # local build (Linux/macOS) 
 
```

## Use cases

### Case A — consumer

GOAL: use brazier as a dependency in your own application
STEPS:

1. Clone registry:

```cmd
git clone git@github.com:brazier-tech/brazier-registry.git 
git -C brazier-registry checkout for-local-using 
```

2. Execute build:

```powershell
# Windows platform 
cd brazier-registry 
.\build.bat 
```

```shell
#Linux/macOS: 
cd brazier-registry 
chmod +x build.sh 
./build.sh 
```

2. Create vcpkg.json in your project:

```json
{ 
    "name": "my-app", 
    "version": "1.0.0", 
    "dependencies": 
    ["brazier"] 
} 
```

3. Create vcpkg-configuration.json next to vcpkg.json:

```json
{ 
    "default-registry": 
        { 
            "kind": "git", 
            "repository": "https://github.com/microsoft/vcpkg", 
            "baseline": "<baseline-from-microsoft-vcpkg>" 
        }, 
    "overlay-ports": [ "<absolute-path-to>/brazier-registry/ports" ] 
}
```

4. Make changes in CMakeLists.txt:

```cmake
find_package(brazier CONFIG REQUIRED) 

target_link_libraries(my_app PRIVATE brazier::brazier)
```

5. configure + build:

```cmd
cmake -B build -S . \ -DCMAKE_TOOLCHAIN_FILE=<vcpkg>/scripts/buildsystems/vcpkg.cmake 
cmake --build build 
```

### Case B — framework developer

GOAL: build brazier from local source code (not from git)
PRECONDITIONS: All the repositories that you need are cloned side by side:

```text
YourPath/
├── brazier/ # core
├── brazierORM/ # orm
├── brazier-logger/ # logger
└── brazier-registry/ # this registry
```

STEPS:

```powershell
# Windows platform
cd brazier-registry
.\build.bat # all packages of brazier
.\build.bat brazier-core # only core
.\build.bat brazier-orm # only orm
.\build.bat brazier-logger # only logger
# e.t.c.
```

```shell
# Linux/macOS
cd brazier-registry
chmod +x build.sh
./build.sh # all packages of brazier
./build.sh brazier-core # only core
./build.sh brazier-orm # only orm
./build.sh brazier-logger # only logger
# e.t.c.
```

EFFECT (when no argument is given):

1. junction/symlink: ports//source -> upstream repositories
2. copy LICENSE files into port directories
3. resolve upstream master SHAs into ports//_resolved_ref.cmake
4. touch _abi_marker.txt (force ABI hash change)
5. clean vcpkg cache (archives, buildtrees, packages)
6. vcpkg remove + install --editable --no-binarycaching

EFFECT (when target port is given, e.g. brazier-orm):

1-3. same as above (cheap, always run)
4. touch _abi_marker.txt only for the target port
5. clean buildtrees/packages only for the target port
6. vcpkg install <target> --recurse --editable
dependencies with unchanged ABI are skipped by vcpkg

RESULT:
your project uses freshly built brazier from LOCAL sources
single-port rebuild takes seconds instead of minutes

## CMake API

### Meta-package

```cmake
find_package(brazier CONFIG REQUIRED) 

target_link_libraries(app PRIVATE brazier::brazier)
```

### Core only

```cmake
find_package(brazier-core CONFIG REQUIRED)

target_link_libraries(app PRIVATE brazier::core) 

# Targets exported by brazier-core: brazier::core - umbrella (static + shared) brazier::core_static - static only brazier::core_shared - shared only 
```

### ORM only

```cmake
find_package(brazier-orm CONFIG REQUIRED) 

target_link_libraries(app PRIVATE brazier::orm) # ORM depends on: brazier-logger, libpq, nlohmann-json 
```

### Logger only

```cmake
find_package(brazier-logger CONFIG REQUIRED) 

target_link_libraries(app PRIVATE brazier::logger) # Logger has no external dependencies
```
