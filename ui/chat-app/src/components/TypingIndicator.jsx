export default function TypingIndicator(){

  return(

    <div className="bg-[#444654]">

      <div className="max-w-3xl mx-auto px-6 py-6 flex gap-4">

        <div className="w-8 h-8 bg-gray-600 rounded"></div>

        <div className="text-gray-400 text-sm animate-pulse">

          Assistant is typing...

        </div>

      </div>

    </div>

  )
}