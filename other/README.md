## cloudflare 
`workers`

```
addEventListener("fetch", (event) => {
    event.respondWith(handleRequest(event.request));
});

const nodes = [
    "",
    ""
];

async function getNodeIndex() {
    const hours = new Date().getHours();
    if(hours >= 4  && hours <= 16 ){
        return 1;
    } else {
        return 0;
    }
}

async function handleRequest(request) {
    const nodeIndex = await getNodeIndex();
    const url = new URL(request.url);
    url.hostname = nodes[nodeIndex];
    const newRequest = new Request(url.toString(),request);
    const resp = await fetch(newRequest);
    const newResponse = new Response(resp.body, resp);
    newResponse.headers.append("nodeIndex", nodeIndex.toString());
    return newResponse;
}
```



`workers`

```
addEventListener("fetch", (event) => {
    event.respondWith(handleRequest(event.request));
});

const nodes = [
    ""
];

async function getNodeIndex() {
    const hours = new Date().getHours();
    if(hours >= 4  && hours <= 16 ){
        return 0;
    } else {
        return 0;
    }
}


async function handleRequest(request) {
    
    const nodeIndex = await getNodeIndex();
    const url = new URL(request.url);
    url.hostname = nodes[nodeIndex];
    const newRequest = new Request(url.toString(),request);

    let secWebSocketProtocol = newRequest.headers.get("Sec-WebSocket-Protocol");
    let location = newRequest.headers.get("Location");
    if(location && location == "swprb64"  && secWebSocketProtocol){
        secWebSocketProtocol = secWebSocketProtocol.replace(/\+/g, '-');
        secWebSocketProtocol = secWebSocketProtocol.replace(/\//g, '_');
        secWebSocketProtocol = secWebSocketProtocol.replace(/=/g, '');
        newRequest.headers.set("Sec-WebSocket-Protocol",secWebSocketProtocol);
        newRequest.headers.delete("Location");
    }
    const resp = await fetch(newRequest);
    const newResponse = new Response(resp.body, resp);
    newResponse.headers.append("nodeIndex", nodeIndex.toString());
    return newResponse;
}
```
