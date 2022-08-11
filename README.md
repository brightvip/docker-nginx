## docker-nginx

Barebones example of deploying
[the official nginx Docker image](https://github.com/docker-library/docs/tree/master/nginx)
to Heroku. Serves an example html file at the root directory.

## Try it now!

Fire up an nginx on [Heroku](https://www.heroku.com/) with a single click:

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

Fire up an nginx on [Railway](https://railway.app/) with a single click:

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/new/template?template=https://github.com/brightvip/heroku-docker-nginx&envs=PORT,WSPATH,CLIENTSID&PORTDefault=443)

This example shows how to leverage [Okteto](https://github.com/okteto/okteto) to develop a  Sample App directly in Okteto.

[![Develop on Okteto](https://okteto.com/develop-okteto.svg)](https://cloud.okteto.com/deploy?repository=https://github.com/brightvip/heroku-docker-nginx%vars=%5B%7B%22name%22%3A%22THEME%22%2C%22value%22%3A%22dark%22%7D%2C%7B%22name%22%3A%22LANG%22%2C%22value%22%3A%22en%22%7D%5D)

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




