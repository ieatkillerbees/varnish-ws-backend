vcl 4.0;

import directors;

# -- Health Check Probe
#probe health_check {
#    .url = "/health";
#    .timeout = 1s;
#    .interval = 5s;
#}

# -- Backend Server Definitions
backend server1 {
    .host = "varnish.tembies.com:8180";
    .probe = health_check;
}
#backend server2 {
#    .host = "varnish.tembies.com:8181";
#    .probe = health_check;
#}
#backend server3 {
#    .host = "varnish.tembies.com:8182";
#    .probe = health_check;
#}

# -- VCL Init
#sub vcl_init {
#    new vdir = directors.round_robin();
#    vdir.add_backend(server1);
#    vdir.add_backend(server2);
#    vdir.add_backend(server3);
#}


# -- ACL for purge
acl purge {
    "127.0.0.1";
}

# -- Handle stripping cookies
sub strip_req_cookies {
    if (req.url !~ "^/admin") {
        if (req.http.Cookie) {
           set req.http.X-Orig-Cookie = req.http.Cookie;
           unset req.http.Cookie;
        }
    }
}

# -- Normalize Accept-Encoding
sub normalize_accept_encoding {
    if (req.http.Accept-Encoding) {
        if (req.http.User-Agent ~ "MSIE 6") {
            unset req.http.Accept-Encoding;
        } elsif (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } elsif (req.http.Accept-Encoding ~ "deflate") {
            set req.http.Accept-Encoding = "deflate";
        } else {
            unset req.http.Accept-Encoding;
        }
    }
}

# -- Set X-OS
sub set_x_os {
    if (req.http.User-Agent ~ "Mac") {
        set req.http.X-OS = "mac";
    } elsif (req.http.User-Agent ~ "Windows") {
        set req.http.X-OS = "windows";
    } elsif (req.http.User-Agent ~ "Linux") {
        set req.http.X-OS = "linux";
    } else {
        set req.http.X-OS = "unknown";
    }
}


# -- VCL Receive
sub vcl_recv {
#    set req.backend_hint= default;

    if (req.http.cache-control) {
        unset req.http.cache-control;
    }

    # Enables PURGE method
    if (req.method == "PURGE") {
        if (!client.ip ~ purge) {
            return(synth(405,"Forbidden"));
        }
        return(purge);
    }

    # Non-standard method will be proxied
    if (req.method != "GET" && req.method != "HEAD" && req.method != "PUT" && req.method != "POST" &&
        req.method != "TRACE" && req.method != "OPTIONS" && req.method != "DELETE") {
        return(pipe);
    }

    # Only mess with GET and HEAD
    if (req.method != "GET" && req.method != "HEAD") {
        return(pass);
    }

    call normalize_accept_encoding;
    call set_x_os;
    call strip_req_cookies;
}

# -- VCL response
sub vcl_backend_response {
    # Set Grace
    # set beresp.grace = 120s;

    if (beresp.http.Authorization && !beresp.http.Cache-Control ~ "public") {
      set beresp.uncacheable = true;
      return (deliver);
    }

    if (bereq.url == "/esi") {
       set beresp.do_esi = true; // Do ESI processing
       set beresp.ttl = 24 h;    // Sets the TTL on the HTML above
    } elseif (bereq.url == "/esi_date") {
       set beresp.ttl = 0s;
    }
}

# -- VCL Deliver
sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }
}