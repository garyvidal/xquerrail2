xquery version "1.0-ml";
(:~
 : The base controller is responsible for all domain controller functions. 
 : Any actions specified in the base controller will be globally accessible by each domain controller.
 : 
 : @author   : Gary Vidal
 : @version  : 2.0  
 :)

module namespace controller = "http://xquerrail.com/controller/base";

(:Global Import Module:)
import module namespace request =  "http://xquerrail.com/request"
   at "/_framework/request.xqy";
   
import module namespace response = "http://xquerrail.com/response"
   at "/_framework/response.xqy";   

import module namespace model = "http://xquerrail.com/model/base"
   at "/_framework/base/base-model.xqy";

import module namespace domain = "http://xquerrail.com/domain"
   at "/_framework/domain.xqy";

import module namespace config = "http://xquerrail.com/config"
   at "/_framework/config.xqy";
   
declare default collation "http://marklogic.com/collation/codepoint";
  
(:Default Imports:)
declare namespace search = "http://marklogic.com/appservices/search";


(:Global Option:)
declare option xdmp:mapping "false";
declare variable $collation := "http://marklogic.com/collation/codepoint";

(:~
 : Initiailizes the request to allow calling into request:* and response:* functions.
 : @param $request - Request map:map representing the request.
 : @return true if the request/response was initialized properly
 :)
declare function controller:initialize($request)
{(
   xdmp:log(("initialize::",$request),"debug"),
   request:initialize($request),
   response:initialize(map:map(),$request),
   response:set-partial(request:partial())
)};
(:~
 : Returns the model associated with the controller.  All actions in base use the controller to define the model.
 :)
declare function controller:model()
{
   let $model := domain:get-controller-model(request:application(),request:controller())
   return
     if($model) then $model
     else fn:error(xs:QName("INVALID-MODEL"),"Invalid Model for application",(request:application(),request:controller()))
};

(:~
 : Action returns the model as an endpoint representing the schema
 :)
declare function controller:schema() {
  (
    response:set-model(controller:model()),
    response:set-body(controller:model()),
    response:set-view("model"),
    response:set-action("model"),
    response:flush()
  )
};

(:~
 : Action returns 
 :)
declare function controller:controller()
{
    domain:get-controller(request:application(),request:controller())
};

(:~
 : Invokes the action associated with the controller and matches the name to the appropriate action
 : @param $action - Name of the action to invoke
 :)
declare function controller:invoke($action)
{
 response:set-model(controller:model()),
 (
   (:REST Actions:)
   if(controller:controller()) then 
       if($action eq "create")      then controller:create()
       else if($action eq "update") then controller:update()
       else if($action eq "get")    then controller:get()
       else if($action eq "delete") then controller:delete()
       else if($action eq "list")   then controller:list()
       else if($action eq "search") then controller:search()
       else if($action eq "put")    then controller:put()
       else if($action eq "post")   then controller:post()
       else if($action eq "binary") then controller:binary()
       (:HTML:)   
       else if($action eq "index")  then controller:index()
       else if($action eq "new")    then controller:new()
       else if($action eq "edit")   then controller:edit()
       else if($action eq "remove") then controller:remove()  
       else if($action eq "save")   then controller:save()
       else if($action eq "details") then controller:details()
       else if($action eq "show")   then controller:show()
       else if($action eq "lookup") then controller:lookup()
       else if($action eq "fields") then controller:fields()
       else if($action eq "export") then controller:export()
       else if($action eq "import") then controller:import()
       else if($action eq "suggest") then controller:suggest()
       else controller:main()   
   else fn:error(xs:QName("CONTROLLER-NOT-EXISTS"),"Controller does not exist",request:controller())
 )
};

(:Controller Required Functions:) 
declare function controller:name() {
   "base"
}; 
(:~
 : Entry for main when no action is specified
 :)
declare function controller:main()
{
   if(request:format() eq "xml") 
   then (
      response:set-controller(controller:name()),
      response:set-format(request:format()),
      response:set-template(config:default-template(request:application())),
      response:set-view("info"),
      response:flush()
   ) else (
     controller:index()  
   )
};
(:~
 : Action returns the specification for the given controller.
 : @deprecated
 :)
declare function controller:info() { 
  <info xmlns:domain="http://xquerrail.com/domain"
      xmlns:search="http://marklogic.com/appservices/search"
      xmlns:builder="http://xquerrail.com/builder">
   
   <action name="create" method="PUT">
    {()}   
   </action>
   
   <action name="get" method="GET">
      <param name="_uuid" required="false"/>
      <param name="id" requred="true"/>
   </action>

   <action name="update" method="UPDATE">
      <param name="id" required="true"/>
   </action>
   
   <action name="delete" method="DELETE">
      <param name="id" required="true"/>
   </action>
   
   <action name="search">
      <param name="query" required="false"/>
      <param name="start" required="true" default="1"/>
      <param name="pg" required="true" default="1"/>
      <param name="ps" required="false" default="ascending" />      
      <param name="sort-order" required="false" default="ascending" />
   </action>
   
   <action name="list" required="true">
      <param name="start" required="true" default="1"/>
      <param name="page" required="true" default="1"/>
      <param name="sort" required="false" />      
      <param name="sort-order" required="false" default="ascending" />
   </action>  
  
  </info>
    
};

(:~
 : Creates an instance of the model representing the controller
 :) 
declare function controller:create() {(
  xdmp:log(("controller:create::",request:params()),"debug"),
  model:create(controller:model(),request:params())
)};

(:~
 :  Returns an instance of the domain which is assigned to the controller
 :) 
declare function controller:get()
{
   model:get(controller:model(),request:params())
};
 
(:~
 : Updates the instance of the controller and returns the value of the update.
 :) 
declare function controller:update()
{
  model:update(
    controller:model(),
    request:params(),
    (),
    request:param("partial-update") = "true" 
  )
};
 
(:~
 :  Deletes an instance of the model assigned to the controller
 :)  
declare function controller:delete()
{
    model:delete(
       controller:model(),
       request:params()
    )
};
 
(:~
 : Provide search interface for model assigned to the controller
 : @param $query - Search query 
 : @param $sort -  Sorting Key to sort results by
 : @param $start 
 :)
declare function controller:search()
{(

   response:set-template(config:default-template(request:application())),
   response:set-view("search"),
   response:set-title(fn:concat("Search ", controller:controller()/@label)),
   response:set-body(model:search(controller:model(),request:params())),
   response:set-data("search-options",model:build-search-options(controller:model())),
   response:flush()
)};
(:~
 : Provide search suggestions for contentType
 :)
declare function controller:suggest()
{(
  let $suggestions :=  model:suggest(controller:model(),request:params())
  return
    <s>
    { for $suggestion in $suggestions return <t>{$suggestion}</t>}
    </s>
)};


(:~
 : Returns a list of records
 :)
declare function controller:list()
{
    xdmp:log(("controller:list::",request:params()),"debug"),
    model:list(
      controller:model(),
      request:params()  
    )
};

(:
 : ==================================
 : Controller HTML Functions
 : ==================================
 :)
 
(:~
 : Default Index Page this is usually associated with a list grid representing the model
 :)
declare function controller:index()
{(
   controller:list()[0],
   if(response:model()/@persistence eq "singleton")   
   then response:set-view("edit")
   else response:set-view("index"),
    response:set-template(config:default-template(request:application())),
    response:set-title(controller:controller()/@label),
    response:flush()
)};

(:~ Show a record  :) 
declare function controller:show()
{
 (   
    response:set-body(controller:get()),
    response:set-template(config:default-template(request:application())),
    response:set-view("show"),  
    response:flush()
 )     
};   
 (:~ Same as show just readonly  :) 
 
declare function controller:details()
{
 (   
    response:set-body(controller:get()),
    response:set-template(config:default-template(request:application())),
    response:set-view("details"),  
    response:flush()
 )     
};   
(:~
 : Returns a HTML representation of the model to create a new instance.
 :)
declare function controller:new()
{(  
    response:set-template(config:default-template(request:application())),
    response:set-title(controller:model()/@label),
    response:set-view("new"),  
    response:flush()
)}; 

(:~
 :  Saves a controller
 :)
declare function controller:save()
{
   let $identity-field := model:get-id-from-params(controller:model(),request:params())
   let $identity-value := (for $fi in $identity-field return map:get(request:params(),$fi))[1]
   let $_ := xdmp:log(("IdentityField:save::",$identity-field,"IdentityValue:save::",$identity-value),"debug")
   let $current := model:get(controller:model(),request:params())
   let $update := 
       try {
         if ($identity-value ne "" and fn:exists($identity-value) and fn:exists($current) )
         then controller:update()
         else controller:create()
   } catch($exception) {
          (:response:set-error($exception/error:code,$exception/error:format-string):)
         xdmp:rethrow()
       }
   return
   if(response:has-error()) 
   then (
      response:set-flash("error",response:error()),
      response:redirect(request:controller(),"edit"),
      response:flush()
   ) else (
      response:set-flash("save","Record has been saved"),
      response:set-body($update),
      response:set-template(config:default-template(request:application())),
      response:set-format("html"),
      response:redirect(request:controller(),"index"),
      response:flush()
   )
};
 
declare function controller:edit()
{(
    response:set-body(controller:get()),
    response:set-title((controller:model()/@label, controller:model()/@name)[1]),
    response:set-template(config:default-template(request:application())),
    response:set-view("edit"), 
    response:flush()
)};

declare function controller:remove()
{
  let $delete := controller:delete()

   (:     try { 
           controller:delete( )
        } catch($exception) {
          response:set-error("404",$exception) 
        }
   :)
  return
  if(response:has-error()) then (
     response:set-flash("error_message","Could not Delete"),
     response:flush()
   ) else ( 
    response:set-flash("status",fn:string($delete)), 
    response:redirect(controller:name(),"remove")
  )
};

declare function controller:lookup()
{(
     model:lookup(controller:model(),request:params())
)};

declare function controller:put() 
{
    model:put(controller:model(),request:body())
};

declare function controller:post() 
{
    let $model := controller:model()
    let $fieldId := domain:get-model-identity-field-name($model)
    let $identityField := domain:get-model-identity-field-name($model)
    let $key := domain:get-field-id($model//domain:element[@name eq $fieldId])
    let $uuid := (fn:data(request:body()//*[(@name, fn:local-name(.)) = ($key,$identityField) ]))[1]
    return
        if($uuid and $uuid ne "") then 
            model:post(controller:model(),request:body())
        else 
           fn:error(xs:QName("INVALID-POST"),"POST does not have UUID")
};

declare function controller:fields()
{(
    (:Call a base function and then just reset:)
    (if(request:param("_mode") = "edit" )
    then controller:edit()
    else controller:new())[0],
    response:set-view("fields"),
    response:flush()
)};

declare function controller:import() {
    response:set-template(config:default-template(request:application())),
    response:set-view("import"),  
    response:flush()
};

declare function controller:export() {
    response:set-template(config:default-template(request:application())),
    response:set-view("export"),  
    response:flush()
};

declare function controller:binary() {
  let $current := model:get(controller:model(),request:params())
  let $field   := controller:model()//domain:element[@name = request:param("name") ]
  let $binaryref := domain:get-field-value($field,$current)
  return  (
     response:is-download(fn:true()),
     response:set-content-type($binaryref/@content-type),
     response:add-response-header("content-disposition",fn:concat("attachment; filename=", xdmp:url-encode(($binaryref/@filename/fn:data(.),request:param("name"))[1]) )),
     response:set-body(fn:doc($binaryref)),
     response:flush()
  )
};
(:
declare function controller:findAndModify() {
   model:findAndModify(request:params())
};
:)