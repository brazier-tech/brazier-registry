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
PRECONDITIONS: four repositories are cloned side by side:

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
.\build.bat 
```

```shell
#Linux/macOS: 
cd brazier-registry 
chmod +x build.sh 
./build.sh 
```

EFFECT:

1. junction/symlink: ports/*/source → upstream repositories
2. copy LICENSE files into port directories
3. touch _abi_marker.txt (force ABI hash change)
4. clean vcpkg cache (archives, buildtrees, packages)
5. vcpkg install --editable --no-binarycaching

RESULT: your project uses freshly built brazier from LOCAL sources

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
