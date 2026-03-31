import ReactMarkdown from "react-markdown"
import remarkGfm from "remark-gfm"
import CodeBlock from "./CodeBlock"

export default function ChatMessage({message}){

  const isUser = message.role==="user"

  return(

    <div>

        <div className="max-w-3xl mx-auto px-6 py-4 flex gap-4 items-start">

            <div className="w-10 h-10 rounded-full bg-[rgba(255,255,255,0.04)] flex items-center justify-center text-xs text-[var(--muted)]">

                {isUser ? "U" : "AI"}

            </div>

            <div className="flex-1 text-[15px] leading-7">

              <div className={isUser ? "" : "message-card"}>
                <ReactMarkdown
                  remarkPlugins={[remarkGfm]}
                  components={{

                    code({inline,className,children}){

                      const match=/language-(\w+)/.exec(className||"")

                      if(!inline && match){

                        return(
                          <CodeBlock
                            language={match[1]}
                            children={String(children)}
                          />
                        )

                      }

                      return <code>{children}</code>

                    }

                  }}
                >

                  {message.content}

                </ReactMarkdown>
              </div>

            </div>

        </div>

    </div>

  )
}