%% Module to shut down CouchDB via HTTP request.

-module(die_couchdb).
-author('Jason Smith <jhs@couchone.com>').

-export([handle_die_req/1]).

-include("couch_db.hrl").

handle_die_req(#httpd{method='POST'}=Req)
    -> ?LOG_DEBUG("Received shutdown request: ~p", [Req])
    , couch_httpd:validate_ctype(Req, "application/json")
    , ok = couch_httpd:verify_is_server_admin(Req)
    , Pid = spawn(fun die/0)
    , ExitCode = 0
    , {ok, _Timer} = timer:send_after(1000, Pid, {die, ExitCode})
    , couch_httpd:send_json(Req, 200, {[{ok, true}]})
    ;

handle_die_req(Req)
    -> couch_httpd:send_method_not_allowed(Req, "POST")
    .

die()
    -> ?LOG_DEBUG("Waiting for shutdown code", [])
    , receive
        {die, Code}
            -> ?LOG_INFO("Shutting down with code: ~p", [Code])
            , init:stop(Code)
        after 10000
            -> ?LOG_ERROR("Aborting shutdown after no code received", [])
        end
    .

% vim: sw=4 sts=4 et
