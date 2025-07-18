#!/bin/bash

# Define folder name based on current date
FOLDER_NAME="market_recaps_$(date +%Y%m%d)"
mkdir -p "$FOLDER_NAME"

# Track failed uploads
FAILED_UPLOADS=()

# Function to add failed upload to tracking
add_failed_upload() {
    FAILED_UPLOADS+=("$1")
}

# Set your Dropbox access token here
DROPBOX_ACCESS_TOKEN="sl.u.AF2H51GlgNOYbsj188cZECEh4qQSxwOqM46wSYxdNSByGGl4_2YFiuGgovdn0I1iVUr6V0iEKCIBUXSS4Vyb0dJ700qm7GJjDpbD1aF9OGn7Llf5uueyZu55ITmb7FwDxIAVeEPTqDDtgRMaFIMAmd5qLdbf8zGYpBatCP2LIEYM8EZ_qpkuUgqk9qok4nhDitUa70Hf9rScquYIlR2v11El9w6JSveXnnmMPBOE8B-Bu9O80lLUV-SePqy5f8_uWPFtBu2lCoAnidFENbvL3VaYzW7W0o0nho3WyU58PjMB9A9roDf1t6dZyf_OrWsb4mGaQjkKMkTWiss7_imdbNK1clUzw_2iT6IhJ28lXgUPfXbMb7CikzaS4kCm0FzKT9vzCzsvFWMxnMUAUiErU5MD61HMiUJvUAI6Dg7q40Hrjqmp2AXea5ym4SL9BoNCqXo6Wm35JEQkS7MkQHw1wKbjvaKQZXj13XQ5vAx9vfcbE3w5gQveYcXbRVnybSMV2Zqm-T_Mco3RYyToIPoGlGyGz0joqbMn8d_aSxMlNfuqEA9OxSu9MYffUxWCMBHuKVw0K7V5npwIWFzqwFyhjcWRNpzVF-3a1AVVij1jVNm66BXI3QG209BHSLkZ7tRp4ZrgIa0JkzAOqtQ7-8SWSt6OoKMe2ayeW_nFIk2NTEamUvDRbMXn1sF5_7Yj-aZD1KrbcHt3V8YAhBGlrc4wpxw0vHKOl8VguaKU0RwANiy53Dc0x-WLQ1Jo62x0ceEQ3b0YxS7QkHjXEyosRIc-dhpHJEzf2n0EW40ntZu2wsxYmlOkJagpXPT4_wqtc6sVVadBJ0eIRjSuw7QiluVPzTJLCkWHAcegl_uJOb1mvSftmO8548HoJaorqIoC_nwZeRLl_hX7LVdu-RS88vBj1RjDsCwIPJbn49n-JuEQUx0hJovEHE75M71fZpOM2xjL60Lb629eIJCax7YI4KBpkn6nQ9zjVK1W03prIvXBW9oXfCTFCr7ZPd49-LpLzZobV4Hg5obSd3BqiW24BJPoEvoyX_1rK-9xmeDzBGqiqHf6wx64JhqY_16ONfYKpt_ZB6g5xYH6VM2wOjm-ajF7CXWmfpksO64uNUvzK2hUwXW2KG333GC4hCcgiTaZ3jtbdlKTm35chMWS90un_QNBqPpfP-JuyF5CJ8gQ8-fPl74bPrZwhPbRA8_hKI_JOqRhNXjVPcZB2znwa3g27A5d2MByBfb_DhfeqADgktfr31Xt2euFRcFXtxr0QjH-utFr716cnUstch15UvABZE74X2cPC5Yi-FLE7yWTbeXnHC0yBuNgRnMolpJxfOo-0Ku_nbJgiEvt-f_Qu_Kmm50Gk83vnSCOXZqo_yPqjNrVOQgpnxhR9hrHWKa1ciQk3yjh6PudyRc_XCcm8oJ6b2vRKwU5f-kG1uBrH_yhMv0ightR1A"

# Function to upload file to Dropbox
upload_to_dropbox() {
    local file_path="$1"
    local dropbox_path="$2"
    
    echo "Uploading $(basename "$file_path") to Dropbox..."
    
    # Check if file exists
    if [ ! -f "$file_path" ]; then
        echo "Error: File $file_path does not exist" >&2
        return 1
    fi
    
    # Upload file to Dropbox
    UPLOAD_RESPONSE=$(curl -s -X POST https://content.dropboxapi.com/2/files/upload \
        --header "Authorization: Bearer $DROPBOX_ACCESS_TOKEN" \
        --header "Dropbox-API-Arg: {\"path\": \"$dropbox_path\", \"mode\": \"overwrite\", \"autorename\": true}" \
        --header "Content-Type: application/octet-stream" \
        --data-binary "@$file_path")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to upload $(basename "$file_path") to Dropbox." >&2
        return 1
    fi
    
    # Check if upload was successful
    if echo "$UPLOAD_RESPONSE" | grep -q '"error"'; then
        echo "Error: Dropbox upload failed for $(basename "$file_path"):" >&2
        echo "$UPLOAD_RESPONSE" >&2
        return 1
    fi
    
    # Create a shared link for the uploaded file
    SHARE_RESPONSE=$(curl -s -X POST https://api.dropboxapi.com/2/sharing/create_shared_link_with_settings \
        --header "Authorization: Bearer $DROPBOX_ACCESS_TOKEN" \
        --header "Content-Type: application/json" \
        --data "{\"path\": \"$dropbox_path\", \"settings\": {\"requested_visibility\": \"public\"}}")
    
    if [ $? -eq 0 ] && ! echo "$SHARE_RESPONSE" | grep -q '"error"'; then
        SHARE_URL=$(echo "$UPLOAD_RESPONSE" | grep -o '"path_display":"[^"]*' | cut -d'"' -f4)
        if [ -n "$SHARE_URL" ]; then
            echo "$(basename "$file_path") uploaded successfully to: $SHARE_URL"
        else
            echo "$(basename "$file_path") uploaded successfully to Dropbox path: $dropbox_path"
        fi
    else
        echo "$(basename "$file_path") uploaded successfully to Dropbox path: $dropbox_path (could not create public link)"
    fi
    
    return 0
}

# Function to download and upload a PDF or convert webpage to PDF and upload
upload_pdf() {
    URL="$1"
    PDF_FILENAME="$2"
    SOURCE_NAME="$3"

    echo "Processing $SOURCE_NAME..."

    DOWNLOAD_SUCCESS=false
    OUTPUT_PATH="$FOLDER_NAME/$PDF_FILENAME"

    # Enhanced URL pattern detection
    if [[ "$URL" == *.pdf* ]] || [[ "$URL" == *"/media/files/attachments/"* ]] || [[ "$URL" =~ \.(pdf)(\?.*)?$ ]]; then
        echo "Attempting direct PDF download for $SOURCE_NAME..."
        
        # Use curl with better error handling
        if curl -L -f -o "$OUTPUT_PATH" "$URL" 2>/dev/null; then
            # Verify it's actually a PDF
            if file --mime-type "$OUTPUT_PATH" 2>/dev/null | grep -q "application/pdf"; then
                echo "$SOURCE_NAME PDF downloaded successfully: $OUTPUT_PATH"
                DOWNLOAD_SUCCESS=true
            else
                echo "Downloaded file is not a PDF, attempting webpage conversion..."
                rm -f "$OUTPUT_PATH"
            fi
        else
            echo "Direct download failed, attempting webpage conversion..."
        fi
    fi

    # If direct download failed, check content-type
    if [ "$DOWNLOAD_SUCCESS" = false ]; then
        echo "Checking content type for $SOURCE_NAME..."
        CONTENT_TYPE=$(curl -s -I -L "$URL" 2>/dev/null | grep -i "Content-Type:" | head -1 | sed 's/Content-Type: *//i' | tr -d '\r')

        if [[ "$CONTENT_TYPE" == *"application/pdf"* ]]; then
            echo "Content-Type indicates PDF. Downloading $SOURCE_NAME..."
            
            if curl -L -f -o "$OUTPUT_PATH" "$URL" 2>/dev/null; then
                if file --mime-type "$OUTPUT_PATH" 2>/dev/null | grep -q "application/pdf"; then
                    echo "$SOURCE_NAME PDF downloaded successfully: $OUTPUT_PATH"
                    DOWNLOAD_SUCCESS=true
                else
                    echo "Downloaded file verification failed, attempting webpage conversion..."
                    rm -f "$OUTPUT_PATH"
                fi
            else
                echo "PDF download failed, attempting webpage conversion..."
            fi
        fi
    fi

    # If still no success, try webpage conversion
    if [ "$DOWNLOAD_SUCCESS" = false ]; then
        echo "Converting $SOURCE_NAME webpage to PDF using Playwright..."
        
        # Check if the Python script exists
        if [ ! -f "./webpage_to_pdf_playwright.py" ]; then
            echo "Error: webpage_to_pdf_playwright.py not found. Please ensure it exists in the current directory." >&2
            add_failed_upload "$SOURCE_NAME"
            return 1
        fi
        
        # Use the Python script with timeout
        timeout 300 python ./webpage_to_pdf_playwright.py "$URL" "$OUTPUT_PATH"
        
        if [ $? -eq 0 ] && [ -f "$OUTPUT_PATH" ]; then
            echo "$SOURCE_NAME webpage converted to PDF successfully: $OUTPUT_PATH"
            DOWNLOAD_SUCCESS=true
        else
            echo "Error: Failed to convert $SOURCE_NAME webpage to PDF. Skipping." >&2
            add_failed_upload "$SOURCE_NAME"
            return 1
        fi
    fi

    # Upload to Dropbox if successful
    if [ "$DOWNLOAD_SUCCESS" = true ]; then
        DROPBOX_PATH="/market_recaps/$(date +%Y%m%d)/$PDF_FILENAME"
        upload_to_dropbox "$OUTPUT_PATH" "$DROPBOX_PATH"
        
        if [ $? -ne 0 ]; then
            echo "Error: Failed to upload $SOURCE_NAME PDF to Dropbox." >&2
            add_failed_upload "$SOURCE_NAME"
            return 1
        fi
        echo ""
        return 0
    else
        echo "Error: Could not process $SOURCE_NAME. Skipping upload." >&2
        add_failed_upload "$SOURCE_NAME"
        return 1
    fi
}

# ===== UPDATED SITES WITH CURRENT URLS ===== #

# --- JPMorgan PDF --- #
upload_pdf "https://am.jpmorgan.com/content/dam/jpm-am-aem/americas/us/en/insights/market-insights/wmr/weekly_market_recap.pdf" "jpmorgan_weekly_market_recap.pdf" "JPMorgan"

# --- Goldman Sachs Market Monitor PDF --- #
upload_pdf "https://am.gs.com/cms-assets/gsam-app/documents/insights/en/2025/market_monitor_06272025.pdf?view=true" "goldman_sachs_market_monitor.pdf" "Goldman Sachs Market Monitor"

# --- RBC PDF --- #
upload_pdf "https://www.rbcwealthmanagement.com/assets/wp-content/uploads/documents/insights/global-insight-weekly.pdf" "rbc_global_insight_weekly.pdf" "RBC"

# --- HSBC PDF --- #
upload_pdf "https://www.assetmanagement.hsbc.co.uk/en/intermediary/news-and-insights/-/media/files/attachments/common/news-and-articles/articles/investment-weekly-11-july-2025" "hsbc_investment_weekly.pdf" "HSBC"

# --- BlackRock PDF --- #
upload_pdf "https://www.blackrock.com/institutions/en-us/literature/market-commentary/global-credit-weekly-20250710.pdf" "blackrock_global_credit_weekly.pdf" "BlackRock"

# --- Goldman Sachs Market Pulse PDF --- #
upload_pdf "https://am.gs.com/cms-assets/gsam-app/documents/insights/en/2025/us-market-pulse_jul2025.pdf?view=true" "goldman_sachs_market_pulse.pdf" "Goldman Sachs Market Pulse"

# --- Sun Life Global Investments PDF --- #
upload_pdf "https://www.sunlifeglobalinvestments.com/en/insights/commentary/portfolio-insights/mfs-week-in-review/#" "sunlife_mfs_week_in_review.pdf" "Sun Life Global Investments"

# --- UBS PDF --- #
upload_pdf "https://secure.ubs.com/global/en/wealthmanagement/insights/chief-investment-office/market-insights/paul-donovan/2025/weekly/who-wants-to-be-a-millionaire.html" "ubs_weekly.pdf" "UBS"

# --- T. Rowe Price PDF --- #
upload_pdf "https://www.troweprice.com/personal-investing/resources/insights/global-markets-weekly-update.html" "troweprice_global_markets_weekly_update.pdf" "T. Rowe Price"

# --- Apollo Academy - Fixed approach --- #
upload_pdf "https://www.apolloacademy.com/outlook-for-public-and-private-markets-4/" "apollo_academy_outlook.pdf" "Apollo Academy"

# --- PGIM Weekly Market Review --- #
upload_pdf "https://www.pgim.com/investments/sirg/commentary/weekly-market-review" "pgim_weekly_market_review.pdf" "PGIM"

# --- Deutsche Wealth CIO Perspectives --- #
upload_pdf "https://www.deutschewealth.com/en/insights/investing-insights/economic-and-market-outlook/cio-perspectives-june-2025.html" "deutsche_wealth_cio_perspectives.pdf" "Deutsche Wealth"

# --- Bank of America Private Bank Capital Market Outlook --- #
upload_pdf "https://www.privatebank.bankofamerica.com/articles/capital-market-outlook-jul-14-2025.html" "bofa_capital_market_outlook.pdf" "Bank of America Private Bank"

# --- Fidelity Canada Week in Review (Direct PDF) --- #
upload_pdf "https://www.fidelity.ca/content/dam/fidelity/en/documents/reviews/week-in-review.pdf" "fidelity_canada_week_in_review.pdf" "Fidelity Canada"

# --- SSGA Midyear GMO --- #
upload_pdf "https://www.ssga.com/us/en/institutional/insights/midyear-gmo" "ssga_midyear_gmo.pdf" "SSGA Midyear"

# --- SSGA Weekly Economic Perspectives --- #
upload_pdf "https://www.ssga.com/us/en/institutional/insights/weekly-economic-perspectives-14-july-2025" "ssga_weekly_economic_perspectives.pdf" "SSGA Weekly"

# --- Mackenzie Investments Weekly Market Snapshot (Direct PDF) --- #
upload_pdf "https://www.mackenzieinvestments.com/content/dam/mackenzie/en/insights/mi-weekly-market-snapshot-en.pdf" "mackenzie_weekly_market_snapshot.pdf" "Mackenzie Investments"

# Print summary of failed uploads
echo ""
echo "=========================================="
echo "UPLOAD SUMMARY"
echo "=========================================="

if [ ${#FAILED_UPLOADS[@]} -eq 0 ]; then
    echo "✅ All files uploaded successfully!"
else
    echo "❌ The following sources failed to upload:"
    for failed in "${FAILED_UPLOADS[@]}"; do
        echo "   - $failed"
    done
    echo ""
    echo "Total failed uploads: ${#FAILED_UPLOADS[@]}"
fi

echo "=========================================="

# Optional: Clean up the downloaded PDF files and folder
# rm -r "$FOLDER_NAME"