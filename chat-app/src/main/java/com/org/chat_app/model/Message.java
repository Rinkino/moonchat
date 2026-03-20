package com.org.chat_app.model;
import java.time.LocalDateTime;

import jakarta.persistence.*;

@Entity
@Table(name = "messages")
public class Message{
    @Id 
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String message;
    private LocalDateTime sentAt;
    private String sender;
    private String receiver;

    public Message(String message, String sender, String receiver){
        this.message = message; 
        this.sender = sender;
        this.receiver = receiver;   
        sentAt = LocalDateTime.now();
    }
    
    public Message() {}

    public Long getId() { return id; }
    public String getMessage() { return message; }
    public String getSender() { return sender; }
    public String getReceiver() { return receiver; }    
    public LocalDateTime getSentAt() { return sentAt; }


}