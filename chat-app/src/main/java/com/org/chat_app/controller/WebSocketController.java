package com.org.chat_app.controller;

import com.org.chat_app.dto.MessageRequest;
import com.org.chat_app.service.ChatService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Controller;

import java.security.Principal;

@Controller
public class WebSocketController {

    @Autowired
    private ChatService chatService;

    @MessageMapping("/chat")
    public void sendMessage(@Payload MessageRequest request, Principal principal) {
        String senderUsername = principal.getName();
        System.out.println("WS message from: " + senderUsername + " to: " + request.getRecipientUsername());
        chatService.sendMessage(request, senderUsername);
    }
    
}