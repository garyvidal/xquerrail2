xquery version "1.0-ml";
(:~
 : <br/>Responsible for URL rewriting
 : <br/>The rewriter intercepts URLs and rewrites the URL.
 : <br/>The rewriter is used to invoke the controller, run tests, and simulate the REST web service.
 : <br/>In most cases it delegates to the controller (/controller.xqy).
 : <br/>For example, given the original URL in the browser:
 : <br/>http://host:port/search?term=science&amp;from=1&amp;to=12
 : <br/>The URL rewriter would rewrite and pass the url to the server as:
 : <br/>http://host:port/app/controller.xqy?action=search&amp;term=science&amp;from=1&amp;to=12
 : <br/>return $request-url A url ready for server resolution.
 :
 : @see http://developer.marklogic.com
 : Setting Up URL Rewriting for an HTTP App Server
 : @see app/controller.xqy
 :
 :)
import module namespace config = "http://xquerrail.com/config" at "/_framework/config.xqy";
declare namespace routing = "http://xquerrail.com/routing";
declare option xdmp:mapping "false";
let $request := xdmp:get-request-url()
let $router := config:get-route-module()
let $routing := xdmp:function(xs:QName("routing:get-route"),$router)
return
   xdmp:apply($routing,$request)