#ifndef LLAMA_BRIDGE_SHIM_H
#define LLAMA_BRIDGE_SHIM_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

bool llama_bridge_init_model(const char *modelPath, int32_t n_ctx, int32_t n_threads);
void llama_bridge_free_model(void);
void llama_bridge_generate(const char *prompt, void (*cb)(const char *, void *), void *userData);
const char *llama_bridge_version(void);

#ifdef __cplusplus
}
#endif

#endif
