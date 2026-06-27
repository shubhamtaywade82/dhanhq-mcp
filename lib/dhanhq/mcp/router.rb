# frozen_string_literal: true

module Dhanhq
  module Mcp
    # Routes MCP tool calls to appropriate handlers
    class Router
      # Route tool call to handler
      #
      # @param tool_name [String] name of the tool to call
      # @param args [Hash] tool arguments
      # @param context [Context] execution context
      # @return [Hash] tool result
      # @raise [Errors::UnknownTool] when tool is not found
      def self.call(tool_name, args, context)
        Validator.validate!(tool_name, args)

        route_portfolio(tool_name, args, context) ||
          route_instrument(tool_name, args, context) ||
          route_market(tool_name, args, context) ||
          route_option(tool_name, args, context) ||
          route_orders(tool_name, args, context) ||
          route_stream(tool_name, args, context) ||
          route_orders_execution(tool_name, args, context) ||
          route_super_orders(tool_name, args, context) ||
          route_conditional_triggers(tool_name, args, context) ||
          route_positions(tool_name, args, context) ||
          route_margin(tool_name, args, context) ||
          route_traders_control(tool_name, args, context) ||
          route_edis(tool_name, args, context) ||
          route_statements(tool_name, args, context) ||
          route_account(tool_name, args, context) ||
          route_expired_options_data(tool_name, args, context) ||
          raise(Errors::UnknownTool, tool_name)
      end

      def self.route_portfolio(tool_name, _args, context)
        return unless tool_name.start_with?("portfolio.")

        action = tool_name.split(".").last
        Tools::Portfolio.new(context).public_send(action)
      end

      def self.route_instrument(tool_name, args, context)
        return unless tool_name.start_with?("instrument.")

        action = tool_name.split(".").last
        Tools::Instrument.new(context).public_send(action, args)
      end

      def self.route_market(tool_name, args, context)
        case tool_name
        when "instrument.ltp", "instrument.quote", "instrument.ohlc",
             "instrument.daily", "instrument.intraday"
          route_instrument(tool_name, args, context)
        end
      end

      def self.route_option(tool_name, args, context)
        case tool_name
        when "option.expiries"
          Tools::Options::Expiries.new(context).call(args)
        when "option.chain"
          Tools::Options::Chain.new(context).call(args)
        when "option.select"
          Tools::Options::Selector.new(context).call(args)
        when "option.prepare"
          Tools::Options::Prepare.new(context).call(args)
        when "option.filter_chain"
          Tools::Options::FilterChain.new(context).call(args)
        when "option.risk_reward"
          Tools::Options::RiskReward.new(context).call(args)
        when "option.probability"
          Tools::Options::Probability.new(context).call(args)
        when "option.theta_analysis"
          Tools::Options::ThetaAnalysis.new(context).call(args)
        when "option.iv_metrics"
          Tools::Options::IvMetrics.new(context).call(args)
        end
      end

      def self.route_orders(tool_name, args, context)
        case tool_name
        when "orders.prepare"
          Tools::Orders.new(context).prepare(args)
        end
      end

      def self.route_orders_execution(tool_name, args, context)
        case tool_name
        when "orders.place"
          Tools::OrdersExecution.new(context).place(args)
        when "orders.modify"
          Tools::OrdersExecution.new(context).modify(args)
        when "orders.cancel"
          Tools::OrdersExecution.new(context).cancel(args)
        when "orders.get"
          Tools::OrdersExecution.new(context).get(args)
        when "orders.get_by_correlation"
          Tools::OrdersExecution.new(context).get_by_correlation(args)
        when "orders.slice"
          Tools::OrdersExecution.new(context).slice(args)
        when "orders.get_trades"
          Tools::OrdersExecution.new(context).get_trades(args)
        when "orders.history"
          Tools::OrdersExecution.new(context).history(args)
        end
      end

      def self.route_super_orders(tool_name, args, context)
        case tool_name
        when "super_orders.place"
          Tools::SuperOrders.new(context).place(args)
        when "super_orders.modify"
          Tools::SuperOrders.new(context).modify(args)
        when "super_orders.cancel_leg"
          Tools::SuperOrders.new(context).cancel_leg(args)
        when "super_orders.all"
          Tools::SuperOrders.new(context).all
        when "super_orders.get"
          Tools::SuperOrders.new(context).get(args)
        end
      end

      def self.route_conditional_triggers(tool_name, args, context)
        case tool_name
        when "conditional_triggers.place"
          Tools::ConditionalTriggers.new(context).place(args)
        when "conditional_triggers.modify"
          Tools::ConditionalTriggers.new(context).modify(args)
        when "conditional_triggers.delete"
          Tools::ConditionalTriggers.new(context).delete(args)
        when "conditional_triggers.all"
          Tools::ConditionalTriggers.new(context).all
        when "conditional_triggers.get"
          Tools::ConditionalTriggers.new(context).get(args)
        end
      end

      def self.route_positions(tool_name, args, context)
        case tool_name
        when "positions.convert"
          Tools::Positions.new(context).convert(args)
        when "positions.exit_all"
          Tools::Positions.new(context).exit_all
        when "positions.active"
          Tools::Positions.new(context).active
        end
      end

      def self.route_margin(tool_name, args, context)
        case tool_name
        when "margin.calculate"
          Tools::Margin.new(context).calculate(args)
        when "margin.calculate_multi"
          Tools::Margin.new(context).calculate_multi(args)
        end
      end

      def self.route_traders_control(tool_name, args, context)
        case tool_name
        when "traders_control.kill_switch_status"
          Tools::TradersControl.new(context).kill_switch_status
        when "traders_control.activate_kill_switch"
          Tools::TradersControl.new(context).activate_kill_switch
        when "traders_control.deactivate_kill_switch"
          Tools::TradersControl.new(context).deactivate_kill_switch
        when "traders_control.configure_pnl_exit"
          Tools::TradersControl.new(context).configure_pnl_exit(args)
        when "traders_control.get_pnl_exit"
          Tools::TradersControl.new(context).get_pnl_exit
        when "traders_control.stop_pnl_exit"
          Tools::TradersControl.new(context).stop_pnl_exit
        end
      end

      def self.route_edis(tool_name, args, context)
        case tool_name
        when "edis.tpin"
          Tools::Edis.new(context).tpin
        when "edis.form"
          Tools::Edis.new(context).form(args)
        when "edis.bulk_form"
          Tools::Edis.new(context).bulk_form(args)
        when "edis.inquire"
          Tools::Edis.new(context).inquire(args)
        end
      end

      def self.route_statements(tool_name, args, context)
        case tool_name
        when "statements.ledger"
          Tools::Statements.new(context).ledger(args)
        when "statements.trade_history"
          Tools::Statements.new(context).trade_history(args)
        end
      end

      def self.route_account(tool_name, args, context)
        case tool_name
        when "account.get_ip"
          Tools::Account.new(context).get_ip
        when "account.set_ip"
          Tools::Account.new(context).set_ip(args)
        when "account.modify_ip"
          Tools::Account.new(context).modify_ip(args)
        when "account.profile"
          Tools::Account.new(context).profile
        end
      end

      def self.route_expired_options_data(tool_name, args, context)
        case tool_name
        when "expired_options_data.get"
          Tools::ExpiredOptionsData.new(context).get(args)
        end
      end

      def self.route_stream(tool_name, args, context)
        case tool_name
        when "stream.subscribe"
          Tools::Stream::Subscribe.new(context).call(args)
        when "stream.unsubscribe"
          Tools::Stream::Unsubscribe.new(context).call(args)
        when "stream.status"
          Tools::Stream::Status.new(context).call(args)
        end
      end
    end
  end
end
