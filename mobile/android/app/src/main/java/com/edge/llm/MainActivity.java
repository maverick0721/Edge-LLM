package com.edge.llm;

import android.os.Bundle;
import android.text.TextUtils;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ScrollView;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import java.util.ArrayList;
import java.util.List;

public final class MainActivity extends AppCompatActivity {
    private final List<ChatMessage> messages = new ArrayList<>();

    private OnDevicePromptEngine engine;
    private TextView statusText;
    private TextView transcriptText;
    private ScrollView transcriptScroll;
    private EditText promptInput;
    private Button prepareButton;
    private Button resetButton;
    private Button sendButton;

    private boolean canGenerate;
    private boolean canDownload;
    private boolean isGenerating;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        engine = new OnDevicePromptEngine(ContextCompat.getMainExecutor(this));

        statusText = findViewById(R.id.statusText);
        transcriptText = findViewById(R.id.transcriptText);
        transcriptScroll = findViewById(R.id.transcriptScroll);
        promptInput = findViewById(R.id.promptInput);
        prepareButton = findViewById(R.id.prepareButton);
        resetButton = findViewById(R.id.resetButton);
        sendButton = findViewById(R.id.sendButton);

        prepareButton.setOnClickListener(view -> prepareLocalModel());
        resetButton.setOnClickListener(view -> resetConversation());
        sendButton.setOnClickListener(view -> sendPrompt());

        resetConversation();
        refreshAvailability();
    }

    @Override
    protected void onDestroy() {
        if (engine != null) {
            engine.close();
        }
        super.onDestroy();
    }

    private void refreshAvailability() {
        engine.refreshAvailability(
                state -> {
                    canGenerate = state.canGenerate;
                    canDownload = state.canDownload;
                    statusText.setText(state.statusText);
                    syncButtons();
                });
    }

    private void prepareLocalModel() {
        setStatus("Preparing the local model through AICore…");
        prepareButton.setEnabled(false);
        engine.downloadModel(
                this::setStatus,
                () -> {
                    setStatus("Local model is ready.");
                    refreshAvailability();
                });
    }

    private void resetConversation() {
        messages.clear();
        messages.add(new ChatMessage("System", "Edge-LLM is ready for fully local Android chat."));
        renderConversation();
        promptInput.setText("");
        isGenerating = false;
        syncButtons();
    }

    private void sendPrompt() {
        String prompt = promptInput.getText().toString().trim();
        if (TextUtils.isEmpty(prompt) || !canGenerate || isGenerating) {
            return;
        }

        promptInput.setText("");
        isGenerating = true;
        setStatus("Generating locally on this Android device…");

        messages.add(new ChatMessage("You", prompt));
        ChatMessage assistantMessage = new ChatMessage("Edge-LLM", "");
        messages.add(assistantMessage);
        renderConversation();
        syncButtons();

        engine.generate(
                prompt,
                new OnDevicePromptEngine.GenerationListener() {
                    @Override
                    public void onPartial(String partialText) {
                        assistantMessage.setContent(partialText);
                        renderConversation();
                    }

                    @Override
                    public void onCompleted(String finalText) {
                        assistantMessage.setContent(finalText);
                        isGenerating = false;
                        setStatus("Local response complete.");
                        renderConversation();
                        syncButtons();
                    }

                    @Override
                    public void onError(String message) {
                        assistantMessage.setContent("Unable to answer locally.");
                        isGenerating = false;
                        setStatus(message);
                        renderConversation();
                        syncButtons();
                    }
                });
    }

    private void renderConversation() {
        StringBuilder builder = new StringBuilder();
        for (ChatMessage message : messages) {
            builder.append(message.getRole())
                    .append(": ")
                    .append(message.getContent())
                    .append("\n\n");
        }
        transcriptText.setText(builder.toString().trim());
        transcriptScroll.post(() -> transcriptScroll.fullScroll(ScrollView.FOCUS_DOWN));
    }

    private void setStatus(String message) {
        statusText.setText(message);
    }

    private void syncButtons() {
        prepareButton.setEnabled(!isGenerating && canDownload);
        resetButton.setEnabled(!isGenerating);
        sendButton.setEnabled(!isGenerating && canGenerate);
    }
}
