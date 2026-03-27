import { useState, useEffect } from "react"
import Sidebar from "./components/Sidebar"
import ChatLayout from "./components/ChatLayout"

function loadChats(){
  try{
    const saved = localStorage.getItem("edge_chats")
    const parsed = saved ? JSON.parse(saved) : []
    return Array.isArray(parsed) ? parsed : []
  } catch {
    return []
  }
}

export default function App(){

  const [chats,setChats] = useState(() => loadChats())
  const [currentChat,setCurrentChat] = useState(() => loadChats()[0]?.id ?? null)

  useEffect(()=>{
    localStorage.setItem("edge_chats",JSON.stringify(chats))
  },[chats])

  function newChat(){

    const chat = {
      id: Date.now(),
      title: "New Chat",
      messages: []
    }

    setChats(prev => [chat,...prev])
    setCurrentChat(chat.id)

    return chat
  }

  function updateMessages(messages, targetChatId = currentChat){
    if(targetChatId === null){
      return
    }
    setChats(prev => prev.map(chat =>
      chat.id === targetChatId ? { ...chat, messages } : chat
    ))
  }

  function renameChat(chatId, title){
    setChats(prev => prev.map(chat =>
      chat.id === chatId ? { ...chat, title } : chat
    ))
  }

  function deleteChat(chatId){
    setChats(prev => prev.filter(chat => chat.id !== chatId))
    if(currentChat === chatId){
      setCurrentChat(chats[0]?.id ?? null)
    }
  }

  const activeChat = chats.find(chat => chat.id === currentChat)

  return(

    <div className="flex h-screen">

      <Sidebar
        chats={chats}
        currentChat={currentChat}
        setCurrentChat={setCurrentChat}
        newChat={newChat}
        renameChat={renameChat}
        deleteChat={deleteChat}
      />

      <ChatLayout
        chat={activeChat}
        updateMessages={updateMessages}
        newChat={newChat}
      />

    </div>

  )
}
