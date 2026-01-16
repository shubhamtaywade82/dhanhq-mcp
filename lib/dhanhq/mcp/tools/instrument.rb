# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      # Instrument discovery and metadata tool
      class Instrument < Base
        # Find tradable instrument
        #
        # @param args [Hash] exchange_segment and symbol
        # @return [Hash] instrument info with all critical fields
        def find(args)
          inst = load(args)

          {
            security_id: inst.security_id,
            symbol: inst.symbol_name,
            display_name: inst.display_name,
            underlying_symbol: inst.underlying_symbol,
            exchange_segment: inst.exchange_segment,
            segment: inst.segment,
            instrument: inst.instrument,
            instrument_type: inst.instrument_type,
            expiry_flag: inst.expiry_flag,
          }
        end

        # Get trading permissions and risk metadata
        #
        # @param args [Hash] exchange_segment and symbol
        # @return [Hash] trading permissions and risk info
        def info(args)
          inst = load(args)
          build_info_response(inst)
        end

        # Get last traded price
        #
        # @param args [Hash] exchange_segment and symbol
        # @return [Hash] LTP data
        def ltp(args)
          load(args).ltp
        end

        # Get full market quote
        #
        # @param args [Hash] exchange_segment and symbol
        # @return [Hash] quote data with depth
        def quote(args)
          load(args).quote
        end

        # Get OHLC snapshot
        #
        # @param args [Hash] exchange_segment and symbol
        # @return [Hash] OHLC data
        def ohlc(args)
          load(args).ohlc
        end

        # Get daily historical candles
        #
        # @param args [Hash] exchange_segment, symbol, from, to
        # @return [Array<Hash>] daily candles
        def daily(args)
          load(args).daily(
            from_date: args["from"],
            to_date: args["to"],
          )
        end

        # Get intraday candles
        #
        # @param args [Hash] exchange_segment, symbol, from, to, interval
        # @return [Array<Hash>] intraday candles
        def intraday(args)
          load(args).intraday(
            from_date: args["from"],
            to_date: args["to"],
            interval: args["interval"],
          )
        end

        private

        def load(args)
          DhanHQ::Models::Instrument.find(
            args["exchange_segment"],
            args["symbol"],
          )
        end

        def build_info_response(inst)
          {
            isin: inst.isin,
            trading_allowed: inst.buy_sell_indicator == "A",
            bracket_supported: inst.bracket_flag == "Y",
            cover_supported: inst.cover_flag == "Y",
            asm_gsm_status: asm_gsm_status(inst),
            mtf_leverage: inst.mtf_leverage,
            buy_margin_pct: inst.buy_co_min_margin_per,
            sell_margin_pct: inst.sell_co_min_margin_per,
          }
        end

        def asm_gsm_status(inst)
          return "NONE" unless inst.asm_gsm_flag == "Y"

          inst.asm_gsm_category
        end
      end
    end
  end
end
