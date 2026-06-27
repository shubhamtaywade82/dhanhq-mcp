# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      # Statements tools - ledger report, trade history
      class Statements < Base
        # Get ledger report for date range
        #
        # @param args [Hash] from_date, to_date
        # @return [Array<Hash>] ledger entries
        def ledger(args)
          from_date = args["from_date"]
          to_date = args["to_date"]
          return { error: "from_date and to_date are required" } unless from_date && to_date

          entries = DhanHQ::Models::LedgerEntry.all(from_date: from_date, to_date: to_date)
          entries.map { |e| serialize_ledger_entry(e) }
        end

        # Get trade history for date range (paginated)
        #
        # @param args [Hash] from_date, to_date, page
        # @return [Array<Hash>] historical trades
        def trade_history(args)
          from_date = args["from_date"]
          to_date = args["to_date"]
          page = args["page"] || 0

          return { error: "from_date and to_date are required" } unless from_date && to_date

          trades = DhanHQ::Models::Trade.history(
            from_date: from_date,
            to_date: to_date,
            page: page,
          )

          trades.map { |t| serialize_trade(t) }
        end

        private

        def serialize_ledger_entry(entry)
          {
            dhan_client_id: entry.dhan_client_id,
            narration: entry.narration,
            voucherdate: entry.voucherdate,
            exchange: entry.exchange,
            voucherdesc: entry.voucherdesc,
            vouchernumber: entry.vouchernumber,
            debit: entry.debit,
            credit: entry.credit,
            runbal: entry.runbal,
          }.compact
        end

        def serialize_trade(trade)
          {
            dhan_client_id: trade.dhan_client_id,
            order_id: trade.order_id,
            exchange_order_id: trade.exchange_order_id,
            exchange_trade_id: trade.exchange_trade_id,
            transaction_type: trade.transaction_type,
            exchange_segment: trade.exchange_segment,
            product_type: trade.product_type,
            order_type: trade.order_type,
            trading_symbol: trade.trading_symbol,
            custom_symbol: trade.custom_symbol,
            security_id: trade.security_id,
            traded_quantity: trade.traded_quantity,
            traded_price: trade.traded_price,
            isin: trade.isin,
            instrument: trade.instrument,
            sebi_tax: trade.sebi_tax,
            stt: trade.stt,
            brokerage_charges: trade.brokerage_charges,
            service_tax: trade.service_tax,
            exchange_transaction_charges: trade.exchange_transaction_charges,
            stamp_duty: trade.stamp_duty,
            create_time: trade.create_time,
            update_time: trade.update_time,
            exchange_time: trade.exchange_time,
            drv_expiry_date: trade.drv_expiry_date,
            drv_option_type: trade.drv_option_type,
            drv_strike_price: trade.drv_strike_price,
            total_value: trade.total_value,
            total_charges: trade.total_charges,
            net_value: trade.net_value,
          }.compact
        end
      end
    end
  end
end
