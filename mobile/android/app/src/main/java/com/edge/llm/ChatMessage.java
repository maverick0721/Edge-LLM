package com.edge.llm;

final class ChatMessage {
    private final String role;
    private String content;

    ChatMessage(String role, String content) {
        this.role = role;
        this.content = content;
    }

    String getRole() {
        return role;
    }

    String getContent() {
        return content;
    }

    void setContent(String content) {
        this.content = content;
    }
}
