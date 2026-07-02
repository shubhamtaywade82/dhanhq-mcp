# frozen_string_literal: true

module Dhanhq
  module Mcp
    module Tools
      # EDIS tools - T-PIN, form generation, status inquiry
      class Edis < Base
        # Generate T-PIN
        #
        # @return [Hash] T-PIN generation result
        def tpin
          result = DhanHQ::Models::Edis.tpin
          normalized_response(result)
        end

        # Generate eDIS form for single stock
        #
        # @param args [Hash] isin, qty, exchange, segment, bulk
        # @return [Hash] eDIS form HTML
        def form(args)
          result = DhanHQ::Models::Edis.form(args)
          if result.is_a?(Hash) && result[:edis_form_html]
            { success: true, edis_form_html: result[:edis_form_html], dhan_client_id: result[:dhan_client_id] }
          else
            { success: false, error: result[:errorMessage] || "Failed to generate eDIS form" }
          end
        end

        # Generate bulk eDIS form
        #
        # @param args [Hash] exchange, segment, bulk, isin, qty
        # @return [Hash] bulk eDIS form HTML
        def bulk_form(args)
          result = DhanHQ::Models::Edis.bulk_form(args)
          if result.is_a?(Hash) && result[:edis_form_html]
            { success: true, edis_form_html: result[:edis_form_html], dhan_client_id: result[:dhan_client_id] }
          else
            { success: false, error: result[:errorMessage] || "Failed to generate bulk eDIS form" }
          end
        end

        # Inquire EDIS status for ISIN
        #
        # @param args [Hash] isin
        # @return [Hash] EDIS status
        def inquire(args)
          isin = args["isin"] || args[:isin]
          return { error: "isin is required" } unless isin

          result = DhanHQ::Models::Edis.inquire(isin)
          normalize_keys(result)
        end

        private

        def normalized_response(response)
          if response.is_a?(Hash)
            if response[:status] == "success" || response[:edisStatus] == "SUCCESS"
              { success: true, message: response[:remarks] || response[:edisStatus] }
            else
              { success: false, error: response[:remarks] || response[:edisStatus] || "Operation failed" }
            end
          else
            { success: false, error: "Invalid response" }
          end
        end

        def normalize_keys(hash)
          hash.transform_keys { |k| k.to_s.underscore.to_sym }
        end
      end
    end
  end
end
