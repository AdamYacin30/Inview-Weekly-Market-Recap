#!/bin/bash

# Define folder name based on current date
FOLDER_NAME="market_recaps_$(date +%Y%m%d )"
mkdir -p "$FOLDER_NAME"

# Initialize array to collect links
DOWNLOAD_LINKS=()

# Function to download and upload a PDF
upload_pdf() {
    PDF_URL="$1"
    PDF_FILENAME="$2"
    SOURCE_NAME="$3"

    echo "Downloading the latest $SOURCE_NAME PDF..."
    wget -O "$FOLDER_NAME/$PDF_FILENAME" "$PDF_URL"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to download $SOURCE_NAME PDF. Skipping to next."
        return 1
    fi

    echo "$SOURCE_NAME PDF downloaded successfully: $FOLDER_NAME/$PDF_FILENAME"

    echo "Uploading $SOURCE_NAME PDF to Gofile..."
    GOFILE_RESPONSE=$(curl -s -F "file=@$FOLDER_NAME/$PDF_FILENAME" https://store1.gofile.io/uploadFile )

    if [ $? -ne 0 ]; then
        echo "Error: Failed to upload $SOURCE_NAME PDF to Gofile. Exiting."
        return 1
    fi

    DOWNLOAD_LINK=$(echo "$GOFILE_RESPONSE" | jq -r ".data.downloadPage")

    if [ -z "$DOWNLOAD_LINK" ]; then
        echo "Error: Could not extract download link for $SOURCE_NAME PDF from Gofile response. Exiting."
        echo "Gofile Response: $GOFILE_RESPONSE"
        return 1
    fi

    echo "$SOURCE_NAME PDF uploaded to Gofile. Public download link: $DOWNLOAD_LINK"

    # Add to array for later summary
    DOWNLOAD_LINKS+=("$SOURCE_NAME: $DOWNLOAD_LINK")
}

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
# Note: Direct PDF download not found. Webpage content will be converted to PDF.
upload_pdf "https://www.sunlifeglobalinvestments.com/en/insights/commentary/portfolio-insights/mfs-week-in-review/#" "sunlife_mfs_week_in_review.pdf" "Sun Life Global Investments"

# --- JH Investments PDF --- #
# Note: Direct PDF download not found. Webpage content will be converted to PDF.
upload_pdf "https://www.jhinvestments.com/weekly-market-recap#market-moving-news" "jhinvestments_weekly_market_recap.pdf" "JH Investments"

# --- UBS PDF --- #
# Note: Direct PDF download not found. Webpage content will be converted to PDF.
upload_pdf "https://secure.ubs.com/global/en/wealthmanagement/insights/chief-investment-office/market-insights/paul-donovan/2025/weekly/who-wants-to-be-a-millionaire.html" "ubs_weekly.pdf" "UBS"

# --- T. Rowe Price PDF --- #
# Note: Direct PDF download not found. Webpage content will be converted to PDF.
upload_pdf "https://www.troweprice.com/personal-investing/resources/insights/global-markets-weekly-update.html" "troweprice_global_markets_weekly_update.pdf" "T. Rowe Price"

# Optional: Clean up the downloaded PDF files and folder
# rm -r "$FOLDER_NAME"

# Final summary of all links
echo ""
echo "===== Summary of All Gofile Download Links ====="
for link in "${DOWNLOAD_LINKS[@]}"; do
    echo "$link"
done
