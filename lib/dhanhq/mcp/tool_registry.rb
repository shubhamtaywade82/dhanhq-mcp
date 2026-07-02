# frozen_string_literal: true

module Dhanhq
  module Mcp
    # Single source of truth for MCP tool metadata, scopes, and dispatch handlers.
    # rubocop:disable Metrics/ClassLength
    class ToolRegistry
      WRITE_TOOLS = %w[
        orders.place orders.modify orders.cancel orders.slice
        super_orders.place super_orders.modify super_orders.cancel_leg
        conditional_triggers.place conditional_triggers.modify conditional_triggers.delete
        positions.convert positions.exit_all
        traders_control.activate_kill_switch traders_control.deactivate_kill_switch
        traders_control.configure_pnl_exit traders_control.stop_pnl_exit
        edis.form edis.bulk_form account.set_ip account.modify_ip
      ].freeze

      INTENT_TOOLS = %w[orders.prepare option.prepare margin.calculate margin.calculate_multi].freeze

      def self.execution_handlers
        %w[place modify cancel get get_by_correlation slice get_trades history].to_h do |action|
          handler = ->(context, args) { Tools::OrdersExecution.new(context).public_send(action, args) }
          ["orders.#{action}", handler]
        end
      end

      def self.super_order_handlers
        %w[place modify cancel_leg get].to_h do |action|
          handler = ->(context, args) { Tools::SuperOrders.new(context).public_send(action, args) }
          ["super_orders.#{action}", handler]
        end
      end

      def self.conditional_trigger_handlers
        %w[place modify delete get].to_h do |action|
          handler = ->(context, args) { Tools::ConditionalTriggers.new(context).public_send(action, args) }
          ["conditional_triggers.#{action}", handler]
        end
      end

      HANDLERS = {
        "portfolio.holdings" => ->(context, _args) { Tools::Portfolio.new(context).holdings },
        "portfolio.positions" => ->(context, _args) { Tools::Portfolio.new(context).positions },
        "portfolio.funds" => ->(context, _args) { Tools::Portfolio.new(context).funds },
        "portfolio.orders" => ->(context, _args) { Tools::Portfolio.new(context).orders },
        "portfolio.trades" => ->(context, _args) { Tools::Portfolio.new(context).trades },
        "instrument.find" => ->(context, args) { Tools::Instrument.new(context).find(args) },
        "instrument.info" => ->(context, args) { Tools::Instrument.new(context).info(args) },
        "instrument.ltp" => ->(context, args) { Tools::Instrument.new(context).ltp(args) },
        "instrument.quote" => ->(context, args) { Tools::Instrument.new(context).quote(args) },
        "instrument.ohlc" => ->(context, args) { Tools::Instrument.new(context).ohlc(args) },
        "instrument.daily" => ->(context, args) { Tools::Instrument.new(context).daily(args) },
        "instrument.intraday" => ->(context, args) { Tools::Instrument.new(context).intraday(args) },
        "option.expiries" => ->(context, args) { Tools::Options::Expiries.new(context).call(args) },
        "option.chain" => ->(context, args) { Tools::Options::Chain.new(context).call(args) },
        "option.select" => ->(context, args) { Tools::Options::Selector.new(context).call(args) },
        "option.prepare" => ->(context, args) { Tools::Options::Prepare.new(context).call(args) },
        "option.filter_chain" => ->(context, args) { Tools::Options::FilterChain.new(context).call(args) },
        "option.risk_reward" => ->(context, args) { Tools::Options::RiskReward.new(context).call(args) },
        "option.probability" => ->(context, args) { Tools::Options::Probability.new(context).call(args) },
        "option.theta_analysis" => ->(context, args) { Tools::Options::ThetaAnalysis.new(context).call(args) },
        "option.iv_metrics" => ->(context, args) { Tools::Options::IvMetrics.new(context).call(args) },
        "orders.prepare" => ->(context, args) { Tools::Orders.new(context).prepare(args) },
        "stream.subscribe" => ->(context, args) { Tools::Stream::Subscribe.new(context).call(args) },
        "stream.unsubscribe" => ->(context, args) { Tools::Stream::Unsubscribe.new(context).call(args) },
        "stream.status" => ->(context, args) { Tools::Stream::Status.new(context).call(args) },
      }.merge(
        execution_handlers,
      ).merge(
        { "super_orders.all" => ->(context, _args) { Tools::SuperOrders.new(context).all } },
        super_order_handlers,
      ).merge(
        { "conditional_triggers.all" => ->(context, _args) { Tools::ConditionalTriggers.new(context).all } },
        conditional_trigger_handlers,
      ).merge(
        {
          "positions.convert" => ->(context, args) { Tools::Positions.new(context).convert(args) },
          "positions.exit_all" => ->(context, _args) { Tools::Positions.new(context).exit_all },
          "positions.active" => ->(context, _args) { Tools::Positions.new(context).active },
          "margin.calculate" => ->(context, args) { Tools::Margin.new(context).calculate(args) },
          "margin.calculate_multi" => ->(context, args) { Tools::Margin.new(context).calculate_multi(args) },
          "traders_control.kill_switch_status" => lambda do |context, _args|
            Tools::TradersControl.new(context).kill_switch_status
          end,
          "traders_control.activate_kill_switch" => lambda do |context, _args|
            Tools::TradersControl.new(context).activate_kill_switch
          end,
          "traders_control.deactivate_kill_switch" => lambda do |context, _args|
            Tools::TradersControl.new(context).deactivate_kill_switch
          end,
          "traders_control.configure_pnl_exit" => lambda do |context, args|
            Tools::TradersControl.new(context).configure_pnl_exit(args)
          end,
          "traders_control.get_pnl_exit" => ->(context, _args) { Tools::TradersControl.new(context).get_pnl_exit },
          "traders_control.stop_pnl_exit" => ->(context, _args) { Tools::TradersControl.new(context).stop_pnl_exit },
          "edis.tpin" => ->(context, _args) { Tools::Edis.new(context).tpin },
          "edis.form" => ->(context, args) { Tools::Edis.new(context).form(args) },
          "edis.bulk_form" => ->(context, args) { Tools::Edis.new(context).bulk_form(args) },
          "edis.inquire" => ->(context, args) { Tools::Edis.new(context).inquire(args) },
          "statements.ledger" => ->(context, args) { Tools::Statements.new(context).ledger(args) },
          "statements.trade_history" => ->(context, args) { Tools::Statements.new(context).trade_history(args) },
          "account.get_ip" => ->(context, _args) { Tools::Account.new(context).get_ip },
          "account.set_ip" => ->(context, args) { Tools::Account.new(context).set_ip(args) },
          "account.modify_ip" => ->(context, args) { Tools::Account.new(context).modify_ip(args) },
          "account.profile" => ->(context, _args) { Tools::Account.new(context).profile },
          "expired_options_data.get" => ->(context, args) { Tools::ExpiredOptionsData.new(context).get(args) },
        },
      ).freeze

      def self.tools
        TOOL_SPEC.map { |tool| enrich(tool) }
      end

      def self.fetch(name)
        tools.find { |tool| tool[:name] == name } || raise(Errors::UnknownTool, name)
      end

      def self.call(name, args, context)
        tool = fetch(name)
        context.policy.authorize!(tool)
        handler = HANDLERS.fetch(name) { raise Errors::UnknownTool, name }
        handler.call(context, args)
      end

      def self.enrich(tool)
        name = tool[:name]
        scope = if WRITE_TOOLS.include?(name)
                  Policy::WRITE_SCOPE
                elsif INTENT_TOOLS.include?(name)
                  Policy::INTENT_SCOPE
                else
                  Policy::READ_ONLY_SCOPE
                end
        tool.merge(scope: scope, version: "1.0.0", risk: scope == Policy::WRITE_SCOPE ? "high" : "low")
      end
      private_class_method :enrich
    end
    # rubocop:enable Metrics/ClassLength
  end
end
