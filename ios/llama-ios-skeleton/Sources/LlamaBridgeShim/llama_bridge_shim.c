#include "LlamaBridgeShim.h"

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if __has_include(<TargetConditionals.h>)
#include <TargetConditionals.h>
#endif

#if defined(TARGET_OS_IOS) && TARGET_OS_IOS
#define LLAMA_RUNTIME_AVAILABLE 1
#else
#define LLAMA_RUNTIME_AVAILABLE 0
#endif

#if LLAMA_RUNTIME_AVAILABLE
#include "../../../third_party/llama.cpp/include/llama.h"

static struct llama_model *g_model = NULL;
static struct llama_context *g_ctx = NULL;
static struct llama_sampler *g_sampler = NULL;
static const struct llama_vocab *g_vocab = NULL;
static bool g_backend_initialized = false;

static void bridge_free_all(void) {
    if (g_sampler != NULL) {
        llama_sampler_free(g_sampler);
        g_sampler = NULL;
    }

    if (g_ctx != NULL) {
        llama_free(g_ctx);
        g_ctx = NULL;
    }

    if (g_model != NULL) {
        llama_model_free(g_model);
        g_model = NULL;
    }

    g_vocab = NULL;
}

static bool bridge_model_loaded(void) {
    return g_model != NULL && g_ctx != NULL && g_sampler != NULL && g_vocab != NULL;
}

static bool bridge_emit_token(llama_token token, void (*cb)(const char *, void *), void *userData) {
    enum llama_token_attr attr = llama_vocab_get_attr(g_vocab, token);
    if ((attr & LLAMA_TOKEN_ATTR_CONTROL) || (attr & LLAMA_TOKEN_ATTR_UNUSED)) {
        return false;
    }

    char piece[1024];
    int32_t n = llama_token_to_piece(g_vocab, token, piece, (int32_t) sizeof(piece) - 1, 0, true);
    if (n <= 0) {
        return false;
    }

    if (n >= (int32_t) sizeof(piece)) {
        n = (int32_t) sizeof(piece) - 1;
    }

    piece[n] = '\0';
    cb(piece, userData);
    return true;
}
#endif

bool llama_bridge_init_model(const char *modelPath, int32_t n_ctx, int32_t n_threads) {
#if LLAMA_RUNTIME_AVAILABLE
    bridge_free_all();

    if (modelPath == NULL || modelPath[0] == '\0') {
        return false;
    }

    if (!g_backend_initialized) {
        llama_backend_init();
        g_backend_initialized = true;
    }

    struct llama_model_params mparams = llama_model_default_params();
    mparams.n_gpu_layers = 0;
    g_model = llama_model_load_from_file(modelPath, mparams);
    if (g_model == NULL) {
        bridge_free_all();
        return false;
    }

    // Reject vocab-only / non-generative files early (common cause of <unk>/symbol output).
    if (!llama_model_has_decoder(g_model) || llama_model_n_params(g_model) < 100000000ULL) {
        bridge_free_all();
        return false;
    }

    struct llama_context_params cparams = llama_context_default_params();
    if (n_ctx > 0) {
        cparams.n_ctx = (uint32_t) n_ctx;
    }
    if (n_threads > 0) {
        cparams.n_threads = n_threads;
        cparams.n_threads_batch = n_threads;
    }
    cparams.n_batch = cparams.n_ctx;

    g_ctx = llama_init_from_model(g_model, cparams);
    if (g_ctx == NULL) {
        bridge_free_all();
        return false;
    }

    g_vocab = llama_model_get_vocab(g_model);
    if (g_vocab == NULL) {
        bridge_free_all();
        return false;
    }

    struct llama_sampler_chain_params sparams = llama_sampler_chain_default_params();
    g_sampler = llama_sampler_chain_init(sparams);
    if (g_sampler == NULL) {
        bridge_free_all();
        return false;
    }

    llama_sampler_chain_add(g_sampler, llama_sampler_init_top_k(40));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_top_p(0.90f, 1));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_temp(0.7f));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_penalties(64, 1.10f, 0.0f, 0.0f));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_dist(LLAMA_DEFAULT_SEED));

    return true;
#else
    (void) modelPath;
    (void) n_ctx;
    (void) n_threads;
    return false;
#endif
}

void llama_bridge_free_model(void) {
#if LLAMA_RUNTIME_AVAILABLE
    bridge_free_all();
#endif
}

void llama_bridge_generate(const char *prompt, void (*cb)(const char *, void *), void *userData) {
#if LLAMA_RUNTIME_AVAILABLE
    if (cb == NULL) {
        return;
    }

    if (!bridge_model_loaded()) {
        cb("[bridge] Model not loaded.\n", userData);
        return;
    }

    if (prompt == NULL || prompt[0] == '\0') {
        cb("[bridge] Empty prompt.\n", userData);
        return;
    }

    llama_memory_t mem = llama_get_memory(g_ctx);
    if (mem != NULL) {
        llama_memory_clear(mem, false);
    }
    llama_sampler_reset(g_sampler);

    const char *tmpl = llama_model_chat_template(g_model, NULL);
    const struct llama_chat_message messages[2] = {
        {
            .role = "system",
            .content = "You are a helpful assistant. Reply in clear, concise English."
        },
        {
            .role = "user",
            .content = prompt
        },
    };

    char *formattedPrompt = NULL;
    int32_t promptLen = 0;

    if (tmpl != NULL) {
        int32_t formattedCap = llama_chat_apply_template(tmpl, messages, 2, true, NULL, 0);
        if (formattedCap > 0) {
            formattedPrompt = (char *) malloc((size_t) formattedCap);
            if (formattedPrompt != NULL) {
                promptLen = llama_chat_apply_template(tmpl, messages, 2, true, formattedPrompt, formattedCap);
            }
        }
    }

    if (formattedPrompt == NULL || promptLen <= 0) {
        const char *fallbackPrefix = "User: ";
        const char *fallbackSuffix = "\nAssistant:";
        size_t fallbackLen = strlen(fallbackPrefix) + strlen(prompt) + strlen(fallbackSuffix);
        formattedPrompt = (char *) malloc(fallbackLen + 1);
        if (formattedPrompt == NULL) {
            cb("[bridge] Failed to allocate prompt buffer.\n", userData);
            return;
        }
        snprintf(formattedPrompt, fallbackLen + 1, "%s%s%s", fallbackPrefix, prompt, fallbackSuffix);
        promptLen = (int32_t) strlen(formattedPrompt);
    }

    int32_t tokenCap = promptLen + 64;
    if (tokenCap < 256) {
        tokenCap = 256;
    }

    llama_token *promptTokens = (llama_token *) malloc((size_t) tokenCap * sizeof(llama_token));
    if (promptTokens == NULL) {
        free(formattedPrompt);
        cb("[bridge] Failed to allocate token buffer.\n", userData);
        return;
    }

    bool isFirst = true;
    if (mem != NULL) {
        isFirst = llama_memory_seq_pos_max(mem, 0) == -1;
    }

    int32_t nPrompt = llama_tokenize(g_vocab, formattedPrompt, promptLen, promptTokens, tokenCap, isFirst, true);
    if (nPrompt < 0) {
        int32_t needed = -nPrompt;
        llama_token *resized = (llama_token *) realloc(promptTokens, (size_t) needed * sizeof(llama_token));
        if (resized == NULL) {
            free(promptTokens);
            free(formattedPrompt);
            cb("[bridge] Failed to resize token buffer.\n", userData);
            return;
        }
        promptTokens = resized;
        tokenCap = needed;
        nPrompt = llama_tokenize(g_vocab, formattedPrompt, promptLen, promptTokens, tokenCap, isFirst, true);
    }

    free(formattedPrompt);

    if (nPrompt <= 0) {
        free(promptTokens);
        cb("[bridge] Tokenization failed.\n", userData);
        return;
    }

    llama_batch batch = llama_batch_get_one(promptTokens, nPrompt);
    if (llama_decode(g_ctx, batch) != 0) {
        free(promptTokens);
        cb("[bridge] Prompt decode failed.\n", userData);
        return;
    }

    free(promptTokens);

    const int maxNewTokens = 256;
    int emittedTokens = 0;

    for (int i = 0; i < maxNewTokens; ++i) {
        llama_token next = llama_sampler_sample(g_sampler, g_ctx, -1);

        if (llama_vocab_is_eog(g_vocab, next)) {
            break;
        }

        if (bridge_emit_token(next, cb, userData)) {
            emittedTokens += 1;
        }

        llama_sampler_accept(g_sampler, next);

        llama_token one = next;
        batch = llama_batch_get_one(&one, 1);
        if (llama_decode(g_ctx, batch) != 0) {
            cb("\n[bridge] Decode stopped early due to backend error.\n", userData);
            break;
        }
    }

    if (emittedTokens == 0) {
        cb("\n[bridge] No readable tokens produced.\n", userData);
    }
#else
    (void) prompt;
    if (cb != NULL) {
        cb("[bridge] llama runtime unavailable in this build.\n", userData);
    }
#endif
}

const char *llama_bridge_version(void) {
#if LLAMA_RUNTIME_AVAILABLE
    return "llama-bridge-ios/4.0";
#else
    return "llama-bridge-shim/1.0";
#endif
}
