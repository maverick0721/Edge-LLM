cmake_minimum_required(VERSION 3.14)
project(llama_host_example LANGUAGES CXX)

# Path to the staged llama.cpp repository (relative to this CMakeLists location)
set(LLAMA_CPP_DIR ${CMAKE_SOURCE_DIR}/../../third_party/llama.cpp)

if (NOT EXISTS ${LLAMA_CPP_DIR}/CMakeLists.txt)
    message(FATAL_ERROR "llama.cpp not found at ${LLAMA_CPP_DIR}. Run scripts/fetch_build_llama.sh first.")
endif()

# Add the llama.cpp project as a subdirectory so we can link to the 'llama' target
add_subdirectory(${LLAMA_CPP_DIR} ${CMAKE_BINARY_DIR}/llama-build EXCLUDE_FROM_ALL)

add_executable(local_llama_simple main.cpp)
target_link_libraries(local_llama_simple PRIVATE llama ${CMAKE_THREAD_LIBS_INIT})
target_compile_features(local_llama_simple PRIVATE cxx_std_17)
target_include_directories(local_llama_simple PRIVATE ${LLAMA_CPP_DIR}/include)

set_target_properties(local_llama_simple PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
)
