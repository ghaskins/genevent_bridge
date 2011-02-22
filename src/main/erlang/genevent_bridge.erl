-module(genevent_bridge).
-behavior(gen_event).

-export([init/1, handle_event/2]).

-export([add_handler/4, delete_handler/2]).

-export([add_genserver_handler/3]).

-record(state, {handler, state}).

add_handler(EventRef, Id, Handler, State) ->
    gen_event:add_handler(EventRef, {?MODULE, Id}, [Handler, State]).

delete_handler(EventRef, Id) ->
    gen_event:delete_handler(EventRef, {?MODULE, Id}, remove_handler).

init([Handler, State]) ->
    {ok, #state{handler=Handler, state=State}}.

handle_event(Event, State) ->
    Handler = State#state.handler,
    case Handler(Event, State#state.state) of
	{ok, NewState} ->
	    {ok, State#state{state=NewState}};
	{ok, NewState, hibernate} ->
	    {ok, State#state{state=NewState}, hibernate};
	remove_handler ->
	    remove_handler
    end.

handle_call(Request, State) ->
    throw(not_implemented).

handle_info(Info, State) ->
    throw(not_implemented).

terminate(Reason, State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%-------------------------------------------------
% genserver specific bridging
%-------------------------------------------------

-record(genserver_state, {serverref}).

genserver_handler(Event, State) ->
    gen_server:cast(State#genserver_state.serverref, {genevent_bridge, Event}),
    {ok, State}.

add_genserver_handler(EventRef, Id, ServerRef) ->
    F = fun(Event, State) -> genserver_handler(Event, State) end,
    add_handler(EventRef, Id, F, #genserver_state{serverref = ServerRef}).
