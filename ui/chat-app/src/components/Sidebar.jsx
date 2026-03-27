import { Plus, Trash, Pencil, Search } from "lucide-react"
import { useState } from "react"

export default function Sidebar({
  chats,
  currentChat,
  setCurrentChat,
  newChat,
  renameChat,
  deleteChat
}){

  const [editing,setEditing] = useState(null)
  const [search,setSearch] = useState("")

  const filteredChats = chats.filter(chat =>
    chat.title.toLowerCase().includes(search.toLowerCase())
  )

  return(

    <div className="w-[260px] bg-[#202123] flex flex-col">

      {/* new chat button */}


      <div className="p-3">
        <button
          onClick={newChat}
          className="flex items-center gap-2 border border-gray-600 w-full p-2 rounded hover:bg-gray-700"
        >
          <Plus size={16}/>
          New Chat
        </button>
      </div>

      {/* search */}


      <div className="px-3 pb-2">
        <div className="flex items-center gap-2 bg-[#2a2b32] p-2 rounded">
          <Search size={14}/>
          <input
            className="bg-transparent outline-none text-sm flex-1"
            placeholder="Search chats"
            value={search}
            onChange={(e)=>setSearch(e.target.value)}
          />
        </div>
      </div>

      {/* chat list */}


      <div className="flex-1 overflow-y-auto px-2">
        {filteredChats.map(chat => (
          <div
            key={chat.id}
            className={`flex items-center justify-between p-2 rounded cursor-pointer text-sm ${
              chat.id === currentChat ? "bg-[#2a2b32]" : "hover:bg-[#2a2b32]"
            }`}
            onClick={()=>setCurrentChat(chat.id)}
          >
            {editing === chat.id ? (
              <input
                className="bg-transparent outline-none text-sm flex-1"
                defaultValue={chat.title}
                autoFocus
                onBlur={(e)=>{
                  renameChat(chat.id,e.target.value)
                  setEditing(null)
                }}
                onKeyDown={(e)=>{
                  if(e.key==="Enter"){
                    renameChat(chat.id,e.target.value)
                    setEditing(null)
                  }
                }}
              />
            ) : (
              <span className="truncate flex-1">
                {chat.title}
              </span>
            )}
            <div className="flex gap-2">
              <Pencil
                size={14}
                onClick={(e)=>{
                  e.stopPropagation()
                  setEditing(chat.id)
                }}
              />
              <Trash
                size={14}
                onClick={(e)=>{
                  e.stopPropagation()
                  deleteChat(chat.id)
                }}
              />
            </div>
          </div>
        ))}
      </div>

    </div>

  )
}
