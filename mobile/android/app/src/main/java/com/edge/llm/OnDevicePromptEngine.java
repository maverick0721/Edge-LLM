package com.edge.llm;

import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.mlkit.genai.common.DownloadCallback;
import com.google.mlkit.genai.common.FeatureStatus;
import com.google.mlkit.genai.common.GenAiException;
import com.google.mlkit.genai.common.StreamingCallback;
import com.google.mlkit.genai.prompt.GenerateContentRequest;
import com.google.mlkit.genai.prompt.GenerateContentResponse;
import com.google.mlkit.genai.prompt.Generation;
import com.google.mlkit.genai.prompt.PromptPrefix;
import com.google.mlkit.genai.prompt.TextPart;
import com.google.mlkit.genai.prompt.java.GenerativeModelFutures;
import java.io.Closeable;
import java.util.concurrent.Executor;

final class OnDevicePromptEngine implements Closeable {
    interface AvailabilityListener {
        void onAvailability(AvailabilityState state);
    }

    interface StatusListener {
        void onStatus(String message);
    }

    interface GenerationListener {
        void onPartial(String partialText);
        void onCompleted(String finalText);
        void onError(String message);
    }

    static final class AvailabilityState {
        final boolean canGenerate;
        final boolean canDownload;
        final String statusText;

        AvailabilityState(boolean canGenerate, boolean canDownload, String statusText) {
            this.canGenerate = canGenerate;
            this.canDownload = canDownload;
            this.statusText = statusText;
        }
    }

    private static final String SYSTEM_PROMPT =
            "You are Edge-LLM running fully local on Android through Gemini Nano. "
                    + "Be concise, clear, and helpful.";

    private final GenerativeModelFutures generativeModel;
    private final Executor mainExecutor;

    OnDevicePromptEngine(Executor mainExecutor) {
        this.mainExecutor = mainExecutor;
        this.generativeModel = GenerativeModelFutures.from(Generation.INSTANCE.getClient());
    }

    void refreshAvailability(AvailabilityListener listener) {
        Futures.addCallback(
                generativeModel.checkStatus(),
                new FutureCallback<Integer>() {
                    @Override
                    public void onSuccess(Integer status) {
                        listener.onAvailability(mapStatus(status != null ? status : FeatureStatus.UNAVAILABLE));
                    }

                    @Override
                    public void onFailure(Throwable throwable) {
                        listener.onAvailability(
                                new AvailabilityState(
                                        false,
                                        false,
                                        "Unable to query on-device model status: " + describeError(throwable)));
                    }
                },
                mainExecutor);
    }

    void downloadModel(StatusListener listener, Runnable onComplete) {
        ListenableFuture<Void> future =
                generativeModel.download(
                        new DownloadCallback() {
                            @Override
                            public void onDownloadStarted(long bytesToDownload) {
                                listener.onStatus("Downloading local model assets via AICore…");
                            }

                            @Override
                            public void onDownloadProgress(long totalBytesDownloaded) {
                                listener.onStatus("Downloaded " + totalBytesDownloaded + " bytes of local model assets…");
                            }

                            @Override
                            public void onDownloadCompleted() {
                                listener.onStatus("On-device model download completed.");
                            }

                            @Override
                            public void onDownloadFailed(GenAiException error) {
                                listener.onStatus("On-device model download failed: " + describeError(error));
                            }
                        });

        Futures.addCallback(
                future,
                new FutureCallback<Void>() {
                    @Override
                    public void onSuccess(Void unused) {
                        onComplete.run();
                    }

                    @Override
                    public void onFailure(Throwable throwable) {
                        listener.onStatus("Unable to prepare the local model: " + describeError(throwable));
                    }
                },
                mainExecutor);
    }

    void generate(String userPrompt, GenerationListener listener) {
        StringBuilder transcript = new StringBuilder();
        GenerateContentRequest request = buildRequest(userPrompt);

        Futures.addCallback(
                generativeModel.generateContent(
                        request,
                        new StreamingCallback() {
                            @Override
                            public void onNewText(String additionalText) {
                                if (additionalText == null || additionalText.isEmpty()) {
                                    return;
                                }
                                transcript.append(additionalText);
                                mainExecutor.execute(() -> listener.onPartial(transcript.toString()));
                            }
                        }),
                new FutureCallback<GenerateContentResponse>() {
                    @Override
                    public void onSuccess(GenerateContentResponse response) {
                        String finalText = transcript.toString().trim();
                        if (finalText.isEmpty()) {
                            finalText = "(Empty local response)";
                        }
                        listener.onCompleted(finalText);
                    }

                    @Override
                    public void onFailure(Throwable throwable) {
                        listener.onError(describeError(throwable));
                    }
                },
                mainExecutor);
    }

    @Override
    public void close() {
        generativeModel.close();
    }

    private static GenerateContentRequest buildRequest(String userPrompt) {
        GenerateContentRequest.Builder builder = new GenerateContentRequest.Builder(new TextPart(userPrompt));
        builder.setPromptPrefix(new PromptPrefix(SYSTEM_PROMPT));
        builder.setCandidateCount(1);
        builder.setMaxOutputTokens(160);
        builder.setTemperature(0.6f);
        builder.setTopK(20);
        return builder.build();
    }

    private static AvailabilityState mapStatus(int status) {
        if (status == FeatureStatus.AVAILABLE) {
            return new AvailabilityState(true, false, "Ready for fully local Android chat.");
        }
        if (status == FeatureStatus.DOWNLOADABLE) {
            return new AvailabilityState(false, true, "The local model is available to download through AICore.");
        }
        if (status == FeatureStatus.DOWNLOADING) {
            return new AvailabilityState(false, false, "AICore is already downloading the local model.");
        }
        return new AvailabilityState(
                false,
                false,
                "On-device model unavailable on this device. AICore and Gemini Nano support are required.");
    }

    private static String describeError(Throwable throwable) {
        Throwable root = throwable;
        while (root.getCause() != null) {
            root = root.getCause();
        }
        String message = root.getMessage();
        if (message == null || message.isEmpty()) {
            return root.getClass().getSimpleName();
        }
        return root.getClass().getSimpleName() + ": " + message;
    }
}
