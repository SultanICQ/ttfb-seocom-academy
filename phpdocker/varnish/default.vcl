vcl 4.0;

backend default {
  .host = "ttfb-webserver:80";
}

sub vcl_recv {
    # Parse out the first IP to avoid chains
    set req.http.X-Forwarded-For = regsub(req.http.X-Forwarded-For, "^([^,]+),?.*$", "\1");

    # Allow purging from ACL
    if (req.method == "PURGE") {
        ban("req.url ~ " + req.url);
        return (hash);
    }

    # Remove Cookies
    unset req.http.Cookie;

    # Cache all others requests
    return (hash);
}

sub vcl_hash {
    hash_data(req.url);
    if (req.http.host) {
        hash_data(req.http.host);
    } else {
        hash_data(server.ip);
    }

    # If the client has allowed cookies, cache them
    if (req.http.Cookie) {
        hash_data(req.http.Cookie);
    }

    # If the client supports compression, keep that in a different cache
    if (req.http.Accept-Encoding) {
        hash_data(req.http.Accept-Encoding);
    }

    return (lookup);
}

sub vcl_backend_response {

    # Remove some headers we never want to see
    unset beresp.http.Server;
    unset beresp.http.X-Powered-By;

    unset beresp.http.Cookie;
    unset beresp.http.Set-Cookie;

    # Define the default grace period to serve cached content
    set beresp.grace = 30s;

    return (deliver);
}

sub vcl_deliver {
    # Happens when we have all the pieces we need, and are about to send the
    # response to the client.
    #
    # You can do accounting or modifying the final object here.

    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }

    # Remove some headers: PHP version
    unset resp.http.X-Powered-By;

    # Remove some headers: Apache version & OS
    unset resp.http.Server;

    # Remove some headers: Varnish
    unset resp.http.Via;
    unset resp.http.X-Varnish;

    unset resp.http.Vary;

    return (deliver);
}