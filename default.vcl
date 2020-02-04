# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.0 format.
vcl 4.0;
import std;

acl purge_ban {
    "localhost";
    "127.0.0.1";
    "SERVER_EXT_IP";
}
acl allowed_monitors {
    "localhost";
    "127.0.0.1";
    "SERVER_EXT_IP";
}

# Default backend definition. Set this to point to your content server.
# Assuming Apache2 is listening on port 8181
backend default {
    .host = "127.0.0.1";
    .port = "8181";
    .max_connections = 250;
    .connect_timeout = 300s;
    .first_byte_timeout = 300s;
    .between_bytes_timeout = 300s;
}

sub vcl_recv {
    # Enforce SSL
    # the PROXY protocol allows varnish to see
    # hitch's listening port (443) as server.ip
	if (std.port(server.ip) != 443) {
		set req.http.location = "https://" + req.http.host + req.url;
		return(synth(301));
	}

    # Add an X-Forwarded-For header with the client IP address.
    if (req.restarts == 0) {
        if (req.http.X-Forwarded-For) {
            set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
        }
        else {
            set req.http.X-Forwarded-For = client.ip;
        }
    }

	if ( ( req.http.host == "monitor.server.health"
        || req.http.host == "health.varnish" )
      && client.ip ~ allowed_monitors
      && ( req.method == "OPTIONS" || req.method == "GET" )
    ) {
      return (synth(200, "OK"));
    }
    
    # Support pour Brotli : experimental
    if(req.http.Accept-Encoding ~ "br" && req.url !~
            "\.(jpg|png|gif|gz|mp3|mov|avi|mpg|mp4|swf|wmf)$" 
            && req.http.user-agent !~ "MSIE") {
        set req.http.X-brotli = "true";
    }
    
    # FROM https://makina-corpus.com/blog/metier/2018/varnish-et-drupal-gerer-un-cache-anonyme-etendu
    # NORMALIZATION OF ACCEPT-ENCODING HEADER
    # either br, gzip, then deflate, then none
    if (req.http.Accept-Encoding) {
        if (req.url ~ "\.(jpeg|jpg|png|gif|ico|gz|tgz|bz2|tbz|mp3|ogg|woff|swf)(\?.*)?$") {
            # No point in compressing these
            unset req.http.Accept-Encoding;
        } elsif (req.http.Accept-Encoding ~ "br" && req.http.user-agent !~ "MSIE") {
           set req.http.Accept-Encoding = "br";
        } elsif (req.http.Accept-Encoding ~ "gzip") {
           set req.http.Accept-Encoding = "gzip";
	    } elsif (req.http.Accept-Encoding ~ "deflate" && req.http.user-agent !~ "MSIE") {
           set req.http.Accept-Encoding = "deflate";
        } else {
           # unkown algorithm
           unset req.http.Accept-Encoding;
        }
    }

    # New from https://www.jeffgeerling.com/blog/2016/use-drupal-8-cache-tags-varnish-and-purge
    # Only allow BAN requests from IP addresses in the 'purge' ACL.
    if (req.method == "BAN") {
        # Same ACL check as above:
        if (!client.ip ~ purge_ban) {
            return (synth(403, "Not allowed."));
        }

        # Logic for the ban, using the Cache-Tags header. For more info
        # see https://github.com/geerlingguy/drupal-vm/issues/397.
        if (req.http.Cache-Tags) {
            ban("obj.http.Cache-Tags ~ " + req.http.Cache-Tags);
        }
        else {
            return (synth(403, "Cache-Tags header missing."));
        }


        # Logic for the ban, using the Purge-Cache-Tags header. For more info
        # see https://github.com/geerlingguy/drupal-vm/issues/397.
        #if (req.http.Purge-Cache-Tags) {
        #    ban("obj.http.Purge-Cache-Tags ~ " + req.http.Purge-Cache-Tags);
        #}
        #else {
        #    return (synth(403, "Purge-Cache-Tags header missing."));
        #}

        # Throw a synthetic page so the request won't go to the backend.
        return (synth(200, "Ban added."));
    }

    # Image Ban
    if (req.method == "URIBAN") {
        ban("req.http.host == " + req.http.host + " && req.url == " + req.url);
        # Throw a synthetic page so the request won't go to the backend.
        return (synth(200, "Ban added."));
      }

    # Websocket support
    # See https://www.varnish-cache.org/docs/4.0/users-guide/vcl-example-websockets.html
    if ( req.http.Upgrade ~ "(?i)websocket" ) {
      return (pipe);
    }
    
    # Only cache GET and HEAD requests (pass through POST requests).
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }
    
    /* 8th: Custom exceptions */
    # Drupal exceptions, edit if we want to cache some AJAX/AHAH request.
    # Add here filters for never cache URLs such as Payment Gateway's callbacks.
    if ( req.url ~ "^/status\.php$"
      || req.url ~ "^/update\.php$"
      || req.url ~ "^/ooyala/ping$"
      || req.url ~ "^/admin/build/features"
      || req.url ~ "^/info/.*$"
      || req.url ~ "^/flag/.*$"
      || req.url ~ "^.*/ajax/.*$"
      || req.url ~ "^.*/ahah/.*$"
      || req.url ~ "^.*/user/.*$"
      || req.url ~ "^.*/admin/.*$"
    ) {
      /* Do not cache these paths */
      return (pass);
    }

    # Alt domains exceptions, if any
    if ( req.http.host == "do-not-cache.com"
    ) {
         return (pass);
    }

    if ( req.url ~ "^/admin/content/backup_migrate/export"
      || req.url ~ "^/admin/config/system/backup_migrate"
    ) {
      return (pipe);
    }
    if ( req.url ~ "^/system/files" ) {
      return (pipe);
    }
    
    /* 9th: Graced objets & Serve from anonymous cahe if all backends are down */
    # See https://www.varnish-software.com/blog/grace-varnish-4-stale-while-revalidate-semantics-varnish
    # set req.http.X-Varnish-Grace = "none";
    if ( ! std.healthy(req.backend_hint) ) {
      # We must do this here since cookie hashing
      unset req.http.Cookie;
      #TODO# Add sick marker
    }
    
    #if (req.method != "GET" &&
    #  req.method != "HEAD" &&
    #  req.method != "PUT" &&
    #  req.method != "POST" &&
    #  req.method != "OPTIONS" &&
    #  req.method != "DELETE") {
       # Non-RFC2616 or CONNECT which is weird, we remove TRACE also.
    #   return(synth(501, "Not Implemented"));
    #}

    # We could add here a custom header grouping User-agent families.
    # Generic URL manipulation.
    # Remove Google Analytics added parameters, useless for our backends.
    if ( req.url ~ "(\?|&)(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=" ) {
      set req.url = regsuball(req.url, "&(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "");
      set req.url = regsuball(req.url, "\?(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "?");
      set req.url = regsub(req.url, "\?&", "?");
      set req.url = regsub(req.url, "\?$", "");
    }
    
    # Strip anchors, server doesn't need it.
    if ( req.url ~ "\#" ) {
      set req.url = regsub(req.url, "\#.*$", "");
    }
    
    # Strip a trailing ? if it exists
    if ( req.url ~ "\?$" ) {
      set req.url = regsub(req.url, "\?$", "");
    }
    
    # Normalize the querystring arguments
    set req.url = std.querysort(req.url);
    
    # Always cache the following static file types for all users.
    # Use with care if we control certain downloads depending on cookies.
    # Be carefull also if appending .htm[l] via Drupal's clean URLs.
    if ( req.url ~ "(?i)\.(bz2|css|eot|gif|gz|br|html?|ico|jpe?g|js|mp3|ogg|otf|pdf|png|rar|svg|swf|tbz|tgz|ttf|woff2?|zip)(\?(itok=)?[a-z0-9_=\.\-]+)?$"
      && req.url !~ "/sites/default/files"
    ) {
        unset req.http.Cookie;
    }
    
    # Remove all cookies that backend doesn't need to know about.
    # See https://www.varnish-cache.org/trac/wiki/VCLExampleRemovingSomeCookies
    if ( req.http.Cookie ) {
      /* Warning: Not a pretty solution */
      # Prefix header containing cookies with ';'
      set req.http.Cookie = ";" + req.http.Cookie;
      # Remove any spaces after ';' in header containing cookies
      set req.http.Cookie = regsuball(req.http.Cookie, "; +", ";");
      # Prefix cookies we want to preserve with one space:
      #   'S{1,2}ESS[a-z0-9]+' is the regular expression matching a Drupal session
      #   cookie ({1,2} added for HTTPS support).
      #   'NO_CACHE' is usually set after a POST request to make sure issuing user
      #   see the results of his post.
      #   'OATMEAL' & 'CHOCOLATECHIP' are special cookies used by Drupal's Bakery
      #   module to provide Single Sign On.
      # Keep in mind we should add here any cookie that should reach the backend
      # such as splash avoiding cookies.
      set req.http.Cookie
        = regsuball(
            req.http.Cookie,
            ";(S{1,2}ESS[a-z0-9]+|NO_CACHE|OATMEAL|CHOCOLATECHIP|big_pipe_nojs)=",
            "; \1="
          );
      # Remove from the header any single Cookie not prefixed with a space until
      # next ';' separator.
      set req.http.Cookie = regsuball(req.http.Cookie, ";[^ ][^;]*", "");
      # Remove any '; ' at the start or the end of the header.
      set req.http.Cookie = regsuball(req.http.Cookie, "^[; ]+|[; ]+$", "");
      #If there are no remaining cookies, remove the cookie header.
      if ( req.http.Cookie == "" ) {
        unset req.http.Cookie;
      }
    }
    
    /* 13th: Session cookie & special cookies bypass caching stage */
    # As we might want to cache some requests, hashed with its cookies, we don't
    # simply pass when some cookies remain present at this point.
    # Instead we look for request that must be passed due to the cookie header.
    if ( req.http.Cookie ~ "SESS"
      || req.http.Cookie ~ "SSESS"
      || req.http.Cookie ~ "NO_CACHE"
      || req.http.Cookie ~ "OATMEAL"
      || req.http.Cookie ~ "CHOCOLATECHIP"
    ) {
      return (pass);
    }
    
}

sub vcl_hash
{
    if(req.http.X-brotli == "true") {
        hash_data("brotli");
    }
}

sub vcl_pipe {
    # Websocket support
    # See https://www.varnish-cache.org/docs/4.0/users-guide/vcl-example-websockets.html
    if ( req.http.upgrade ) {
      set bereq.http.upgrade = req.http.upgrade;
    }
    # Avoid pipes like plague
    set req.http.connection = "close";
    return(pipe);
}


sub vcl_synth {
    # Enforce SSL
	if (resp.status == 301 || resp.status == 302) {
		set resp.http.location = req.http.location;
		return (deliver);
	}
    
    # Note that max_restarts defaults to 4
    # SeeV3 https://www.varnish-cache.org/trac/wiki/VCLExampleRestarts
    if ( resp.status == 503
      && req.restarts < 4
    ) {
      return (restart);
    }
}

sub vcl_backend_fetch
{
    if(bereq.http.X-brotli == "true") {
        set bereq.http.Accept-Encoding = "br";
        unset bereq.http.X-brotli;
    } else {
        set bereq.http.Accept-Encoding = "gzip";
    }
}

sub vcl_backend_response {

    # Happens after we have read the response headers from the backend.
    #
    # Here you clean the response headers, removing silly Set-Cookie headers
    # and other mistakes your backend does.

    if (beresp.http.X-No-Cache) {
        set beresp.uncacheable = true;
        return (deliver);
    }
    
    # HTTP/1.0 Pragma: nocache support
    if (beresp.http.Pragma ~ "nocache") {
        set beresp.uncacheable = true;
        set beresp.ttl = 120s; # how long not to cache this url.
    }
    
    if (bereq.url ~ "\.(css|js|jpeg|jpg|png|gif|ico|gz|tgz|bz2|tbz|mp3|ogg|woff|eot|ttf|svg|otf|swf|html|htm|htc|map|json)") {

        # Don't allow static files to set cookies.
        unset beresp.http.set-cookie;

        # Enforce varnish TTL of static files
        set beresp.ttl = 1h;

        # will make vcl_deliver reset the Age: header
        set beresp.http.magic_age_marker = "1";

        # Enforce Browser cache control policy
        unset beresp.http.Cache-Control;
        unset beresp.http.expires;
        set beresp.http.Cache-Control = "public, max-age=2419200";
    }
    
    # See https://www.varnish-cache.org/docs/4.0/users-guide/vcl-grace.html
    # See https://www.varnish-software.com/blog/grace-varnish-4-stale-while-revalidate-semantics-varnish
    set beresp.grace = 1h;
    
    set beresp.http.X-Url = bereq.url;
	set beresp.http.X-Host = bereq.http.host;
    
    if ( bereq.url ~ "(?i)\.(bz2|css|eot|gif|gz|br|html?|ico|jpe?g|js|mp3|ogg|otf|pdf|png|rar|svg|swf|tbz|tgz|ttf|woff2?|zip)(\?(itok=)?[a-z0-9_=\.\-]+)?$"
    ) {
      unset beresp.http.set-cookie;
    }
    
    /* Drupal 8's Big Pipe support */
    # Tentative support, maybe 'set beresp.ttl = 0s;' is also needed
    if ( beresp.http.Surrogate-Control ~ "BigPipe/1.0" ) {
      set beresp.do_stream = true;
      # Varnish gzipping breaks streaming of the first response
      set beresp.do_gzip = false;
    }
}

sub vcl_deliver {
    # Happens when we have all the pieces we need, and are about to send the
    # response to the client.
    #
    # You can do accounting or modifying the final object here.
    set resp.http.X-Varnish-Cache-Hits = obj.hits;

    # magic marker use to avoid giving real age of object to browsers
    if (resp.http.magic_age_marker) {
        unset resp.http.magic_age_marker;
        set resp.http.age = "0";
    }

    # Happens when we have all the pieces we need, and are about to send the
    # response to the client.
    #
    # You can do accounting or modifying the final object here.
    # Remove ban-lurker friendly custom headers when delivering to client.
    unset resp.http.X-Url;
    unset resp.http.X-Host;
    
    # Comment these for easier Drupal cache tag debugging in development.
    unset resp.http.X-Cache-Tags;
    unset resp.http.X-Cache-Contexts;
    
    # See https://www.varnish-cache.org/docs/4.0/users-guide/purging.html#bans
    unset resp.http.X-Host;
    unset resp.http.X-Url;
    
    # Purge's headers can become quite big, causing issues in upstream proxies, so we clean it here
    unset resp.http.Purge-Cache-Tags;

    if (obj.hits > 0) {
        set resp.http.Cache-Tags = "HIT";
    }
    else {
        set resp.http.Cache-Tags = "MISS";
    }
    
}

sub vcl_backend_error {
    # SeeV3 https://www.varnish-cache.org/trac/wiki/VCLExampleRestarts
    if ( bereq.retries < 4 ) {
      return (retry);
    }
}


