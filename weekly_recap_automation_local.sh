#!/bin/bash

# Define folder name based on current date
FOLDER_NAME="market_recaps_$(date +%Y%m%d)"
mkdir -p "$FOLDER_NAME"

# Function to download and upload a PDF or convert webpage to PDF and upload
upload_pdf() {
    URL="$1"
    PDF_FILENAME="$2"
    SOURCE_NAME="$3"

    echo "Processing $SOURCE_NAME..."

    DOWNLOAD_SUCCESS=false

    # Prioritize direct PDF download if URL ends with .pdf or contains a common direct download pattern
    if [[ "$URL" == *.pdf* ]] || [[ "$URL" == *"/media/files/attachments/"* ]]; then
        echo "Attempting direct PDF download for $SOURCE_NAME..."
        wget -O "$FOLDER_NAME/$PDF_FILENAME" "$URL"

        if [ $? -eq 0 ]; then
            echo "$SOURCE_NAME PDF downloaded successfully: $FOLDER_NAME/$PDF_FILENAME"
            DOWNLOAD_SUCCESS=true
        else
            echo "Warning: Direct PDF download failed for $SOURCE_NAME. Attempting webpage conversion." >&2
        fi
    fi

    # If not directly downloaded, try content-type check or force Playwright
    if [ "$DOWNLOAD_SUCCESS" = false ]; then
        # Check content type if direct download failed or URL was not .pdf
        # Use curl to get content type more reliably        CONTENT_TYPE=$(curl -s -I -L "$URL" | grep -i "Content-Type" | sed -n 's/Content-Type: \(.*\)\r/\1/p')')

        if [[ "$CONTENT_TYPE" == "application/pdf" ]]; then
            echo "Downloading the latest $SOURCE_NAME PDF (via content-type check)..."
            wget -O "$FOLDER_NAME/$PDF_FILENAME" "$URL"

            if [ $? -eq 0 ]; then
                echo "$SOURCE_NAME PDF downloaded successfully: $FOLDER_NAME/$PDF_FILENAME"
                DOWNLOAD_SUCCESS=true
            else
                echo "Error: Failed to download $SOURCE_NAME PDF (via content-type check). Skipping to next." >&2
                return 1
            fi
        else
            echo "Converting $SOURCE_NAME webpage to PDF using Playwright..."
            # Use the enhanced Python script
            python ./webpage_to_pdf_playwright.py "$URL" "$FOLDER_NAME/$PDF_FILENAME"

            if [ $? -ne 0 ]; then
                echo "Error: Failed to convert $SOURCE_NAME webpage to PDF. Skipping to next." >&2
                return 1
            fi

            echo "$SOURCE_NAME webpage converted to PDF successfully: $FOLDER_NAME/$PDF_FILENAME"
            DOWNLOAD_SUCCESS=true
        fi
    fi

    if [ "$DOWNLOAD_SUCCESS" = true ]; then
        echo "Uploading $SOURCE_NAME PDF to Gofile..."
        GOFILE_RESPONSE=$(curl -s -F "file=@$FOLDER_NAME/$PDF_FILENAME" https://store1.gofile.io/uploadFile)

        if [ $? -ne 0 ]; then
            echo "Error: Failed to upload $SOURCE_NAME PDF to Gofile. Exiting." >&2
            return 1
        fi
        DOWNLOAD_LINK=$(echo "$GOFILE_RESPONSE" | sed -n 's/.*"downloadPage":"\([^"]*\)".*/\1/p')
        if [ -z "$DOWNLOAD_LINK" ]; then
            echo "Error: Could not extract download link for $SOURCE_NAME PDF from Gofile response. Exiting." >&2
            echo "Gofile Response: $GOFILE_RESPONSE" >&2
            return 1
        fi

        echo "$SOURCE_NAME PDF uploaded to Gofile. Public download link: $DOWNLOAD_LINK"
        echo ""
    else
        echo "Error: Could not process $SOURCE_NAME. Skipping upload." >&2
    fi
}

# ===== ORIGINAL SITES ===== #

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

# --- JH Investments PDF --- #
upload_pdf "https://www.jhinvestments.com/weekly-market-recap#market-moving-news" "jhinvestments_weekly_market_recap.pdf" "JH Investments"

# --- UBS PDF --- #
upload_pdf "https://secure.ubs.com/global/en/wealthmanagement/insights/chief-investment-office/market-insights/paul-donovan/2025/weekly/who-wants-to-be-a-millionaire.html" "ubs_weekly.pdf" "UBS"

# --- T. Rowe Price PDF --- #
upload_pdf "https://www.troweprice.com/personal-investing/resources/insights/global-markets-weekly-update.html" "troweprice_global_markets_weekly_update.pdf" "T. Rowe Price"

# ===== NEW SITES WITH CORRECTED APPROACH ===== #

# --- Apollo Academy - Using direct PDF link pattern --- #
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

# Optional: Clean up the downloaded PDF files and folder
# rm -r "$FOLDER_NAME"


