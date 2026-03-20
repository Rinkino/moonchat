package com.org.chat_app.controller;
import com.org.chat_app.dto.MessageRequest;
import com.org.chat_app.service.ChatService;

import com.org.chat_app.model.Message;
import com.org.chat_app.repository.UserRepository;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;


@RestController
@RequestMapping("/chat")
public class ChatController {

    @Autowired
    private ChatService chatService;

    @Autowired
    private UserRepository userRepository;

    @PostMapping("/send")
    public void sendMessage(@RequestBody MessageRequest request, @AuthenticationPrincipal String senderUsername) {
        chatService.sendMessage(request, senderUsername);
    }

    @GetMapping("/history/{otherUsername}")
    public List<Message> getHistory(@PathVariable String otherUsername,
                                    @AuthenticationPrincipal String currentUser) {
        return chatService.getConversation(currentUser, otherUsername);
    }

    @GetMapping("/users")
    public List<String> getUsers(@AuthenticationPrincipal String currentUser) {
        return userRepository.findAll().stream()
            .map(u -> u.getUsername())
            .filter(name -> !name.equals(currentUser))
            .toList();
    }

}