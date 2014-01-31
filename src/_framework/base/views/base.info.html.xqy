
(:@GENERATED@:)
xquery version "1.0-ml";
declare default element namespace "http://www.w3.org/1999/xhtml";
import module namespace response = "http://xquerrail.com/response" at "/_framework/response.xqy";

declare namespace domain = "http://xquerrail.com/domain";

declare option xdmp:output "indent-untyped=yes";
declare variable $response as map:map external;

let $init := response:initialize($response)
let $controller := response:controller()
return
<div class="info-view">
 for $c in $controller 
 return 
    <div class="controller">{$c}</div>
</div>