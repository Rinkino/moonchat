package com.org.chat_app.service;

import com.org.chat_app.dto.MessageRequest;
import com.org.chat_app.model.Message;
import com.org.chat_app.repository.MessageRepository;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

@Service
public class ChatService {

    @Autowired
    private MessageRepository messageRepository;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    public void sendMessage(MessageRequest request, String senderUsername) {
        Message message = new Message(
            request.getContent(),
            senderUsername,
            request.getRecipientUsername()
        );
        messageRepository.save(message);

        System.out.println("Calling convertAndSendToUser for: " + request.getRecipientUsername());

        messagingTemplate.convertAndSendToUser(
            request.getRecipientUsername(),
            "queue/messages",
            message
        );
        System.out.println("Done sending");

    }
    public List<Message> getConversation(String user1, String user2) {
        return messageRepository.findConversation(user1, user2);
    }
}