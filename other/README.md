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
