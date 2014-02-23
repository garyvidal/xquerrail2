xquery version "1.0-ml";

module namespace base = "http://xquerrail.com/engine";
    
import module namespace engine  = "http://xquerrail.com/engine"
  at "/_framework/engines/engine.base.xqy";
  
import module namespace config = "http://xquerrail.com/config"
  at "/_framework/config.xqy";

import module namespace request = "http://xquerrail.com/request"
   at "/_framework/request.xqy";
   
import module namespace response = "http://xquerrail.com/response"
   at "/_framework/response.xqy";
   

declare namespace tag = "http://xquerrail.com/tag";  

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:output "method=xml";

(:~
 : You initialize your variables
 :)
declare variable $request := map:map() ;
declare variable $response := map:map();
declare variable $context := map:map();

(:~
   Initialize  Any custom tags your engine handles so the system can call 
   your custom transform functions
 :)
declare variable $custom-engine-tags as xs:QName*:= 
(
  fn:QName("engine","to-xml")
);
(:Set your engines custom transformer:)
declare variable $custom-transform-function := (
   xdmp:function(xs:QName("engine:custom-transform"),"/_framework/engines/engine.json.xqy")
);
(:~
 : The Main Controller will call your initialize method
 : and register your engine with the engine.base.xqy
 :)
declare function engine:initialize($_response,$_request){ 
(
  let $init := 
  (
       response:initialize($_response),
       request:initialize($_request),
       xdmp:set($response,$_response),
       engine:set-engine-transformer($custom-transform-function),
       engine:register-tags($custom-engine-tags)
  )
  return
   engine:render()
)
};


declare function engine:render-xml()
{   
  response:body()
};
(:~
  Handle your custom tags in this method or the method you have assigned  
  initialized with the base.engine
  It is important that you only handle your custom tags and
  any content that is required to be consumed by your tags
 :)
declare function engine:custom-transform($node as item())
{  
   $node
};
(:~
 : The Kernel controller will call your render method.
 : From this point it is up to your engine to handle 
 : to initialize any specific response settings and
 : and start the rendering process 
 :)
declare function engine:render()
{
   if(response:redirect()) 
   then xdmp:redirect-response(response:redirect())
   else 
   (
     (:Set the response content type:)
     if(response:content-type())
     then xdmp:set-response-content-type(response:content-type())
     else xdmp:set-response-content-type("text/xml"),
     let $view := response:view()
     let $exists := engine:view-exists($view)
     return
     if($exists) then engine:render-view() else  engine:render-xml()
   )
};

