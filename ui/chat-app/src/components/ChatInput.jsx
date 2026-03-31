import { useState } from "react"

export default function ChatInput({ send }){

  const [text,setText] = useState("")

  function submit(){

    if(!text.trim()) return

    send(text)

    setText("")
  }

  return(

    <div className="border-t border-[rgba(255,255,255,0.04)] p-4">
        <div className="max-w-3xl mx-auto flex gap-3 items-center">
            <input
              className="flex-1 input-pill p-3 rounded-l-full outline-none placeholder:text-gray-400 text-sm"
              placeholder="Send a message..."
              value={text}
              onChange={(e)=>setText(e.target.value)}
              onKeyDown={(e)=>{
                if(e.key==="Enter"){
                  submit()
                }
              }}
            />
            <button
              onClick={submit}
              className="btn-accent px-5 py-2 rounded-r-full"
            >
              Send
            </button>
        </div>
    </div>

  )
}