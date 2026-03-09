package com.edge.llm

import okhttp3.*

class MainActivity {

    val client = OkHttpClient()

    fun sendPrompt(prompt:String){

        val request = Request.Builder()
            .url("http://localhost:8000/generate")
            .post(
                RequestBody.create(
                    MediaType.parse("application/json"),
                    "{\"text\":\"$prompt\"}"
                )
            )
            .build()

        client.newCall(request).enqueue(object: Callback {

            override fun onFailure(call:Call,e:IOException){}

            override fun onResponse(call:Call,response:Response){

                val body = response.body()?.string()

                println(body)
            }
        })
    }
}