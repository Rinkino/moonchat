package com.org.chat_app.dto;

public class MessageRequest {
    private String content;
    private String recipientUsername;

    public String getContent() { return content; }
    public String getRecipientUsername() { return recipientUsername; }

    public void setContent(String content) { this.content = content; }
    public void setRecipientUsername(String recipientUsername) { this.recipientUsername = recipientUsername; }
}