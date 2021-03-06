%%%-------------------------------------------------------------------
%% @doc epl_ets_tab_map module.
%% This module provides an APIs for manipulating a data structure which is
%% showed in a table in the web UI in the ETS section.
%% @end
%%%-------------------------------------------------------------------

-module(epl_ets_tab_map).

%% API
-export([update_node/3]).

%%====================================================================
%% API functions
%%====================================================================

%% @doc Updates the node ETS table section in Vizceral map.
-spec update_node(Node :: atom(), ETSCallTrace :: list(), Viz :: map()) -> map().
update_node(Node, ETSCallTrace, Viz) ->
    ETSTabsMetric = get_ets_metric(Node, ETSCallTrace),
    create_ets_tab_map(Node, ETSTabsMetric, Viz).

%%====================================================================
%% Internals
%%====================================================================

get_ets_metric(Node, ETSCallTrace) ->
    Tabs = epl_ets_metric:get_node_ets_tabs(Node),
    TabsInfo = epl_ets_metric:get_ets_tabs_info(Node, Tabs),
    TabsCallStats = epl_ets_metric:get_ets_call_stats(ETSCallTrace),
    [merge_metrics(Tab, [TabsInfo, TabsCallStats]) || Tab <- Tabs].

merge_metrics(Tab, Metrics) ->
    lists:foldl(fun(Metric, Map) ->
                        maps:merge(Map, get_metric_val(Tab, Metric))
                end, #{}, Metrics).

get_metric_val(Tab, {Type, Metric}) ->
    #{<<"tab_id">> => namify(Tab),
      <<"tab_trace_id">> => make_trace_tab_id(Tab),
      namify(Type) => proplists:get_value(Tab, Metric)}.

create_ets_tab_map(Node, ETSTabsMetric, Viz) ->
    NewNodeTabs = #{name => epl_viz_map:namify(Node), tabs => ETSTabsMetric},
    {_, RestTabs} = pull_tab(Node, Viz, maps:is_key(etsNodeTabs, Viz)),
    maps:merge(Viz, #{etsNodeTabs => [NewNodeTabs | RestTabs]}).

pull_tab(Name, Entity, true) ->
    #{etsNodeTabs := NodeTabs} = Entity,
    {NodeTab, Rest} = lists:partition(
                       fun(A) ->
                               maps:get(name, A) == namify(Name)
                       end, NodeTabs),
    {NodeTab, Rest};
pull_tab(_Name, _Entity, false) ->
    {null, []}.

namify(Name) ->
    epl_viz_map:namify(Name).

make_trace_tab_id(Tab) when is_reference(Tab) ->
    RefBin = term_to_binary(Tab),
    binary_to_list(RefBin);
make_trace_tab_id(Tab) ->
    namify(Tab).
