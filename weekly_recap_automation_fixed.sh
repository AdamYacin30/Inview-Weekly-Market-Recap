#!/bin/bash

# Define folder name for market recaps
FOLDER_NAME="market_recaps_$(date +%Y%m%d)"
mkdir -p "$FOLDER_NAME"

# List of URLs to process
# Each entry is a space-separated pair: "URL" "FILENAME_PREFIX"
# Add URLs to SKIP_URLS if they consistently cause issues or require manual intervention

# NOTE: JH Investments requires login, so it\"s skipped.
# Sun Life Global Investments does not provide a direct PDF for MFS Week in Review, so it will be converted from webpage.

URLS=(
    "https://www.franklintempleton.com/investor/investments/investment-solutions/fixed-income/fixed-income-insights" "franklin_templeton_fixed_income_insights"
    "https://www.pimco.com/en-us/insights/economic-and-market-commentary/global-economic-outlook" "pimco_global_economic_outlook"
    "https://www.blackrock.com/us/individual/insights/blackrock-investment-institute/weekly-commentary" "blackrock_weekly_commentary"
    "https://www.fidelity.com/insights/market-and-economic-insights/market-outlook" "fidelity_market_outlook"
    "https://www.schroders.com/en/us/institutional/insights/economics/" "schroders_economics_insights"
    "https://www.ubs.com/global/en/wealth-management/chief-investment-office/market-insights.html" "ubs_market_insights"
    "https://www.morganstanley.com/ideas/global-macro-outlook" "morgan_stanley_global_macro_outlook"
    "https://www.goldmansachs.com/insights/pages/gs-research.html" "goldman_sachs_market_monitor"
    "https://www.rbcwealthmanagement.com/us/en/insights/global-insight-weekly/document" "rbc_global_insight_weekly"
    "https://www.assetmanagement.hsbc.co.uk/en/intermediary/news-and-insights/-/media/files/attachments/common/news-and-articles/articles/investment-weekly-11-july-2025" "hsbc_investment_weekly"
    "https://www.blackrock.com/institutions/en-us/literature/market-commentary/global-credit-weekly-20250710.pdf" "blackrock_global_credit_weekly"
    "https://am.gs.com/cms-assets/gsam-app/documents/insights/en/2025/us-market-pulse_jul2025.pdf?view=true" "goldman_sachs_market_pulse"
    "https://www.sunlife.ca/en/support/download-our-app/my-sun-life-mobile/" "sunlife_mfs_week_in_review"
    "https://www.jhinvestments.com/weekly-market-recap#market-moving-news" "jh_investments_weekly_recap"
    "https://www.apolloacademy.com/outlook-for-public-and-private-markets-4/" "apollo_academy_outlook"
    "https://www.ssga.com/us/en/institutional/insights/midyear-gmo" "ssga_midyear_gmo"
    "https://www.privatebank.bankofamerica.com/articles/capital-market-outlook-jul-14-2025.html" "bank_of_america_capital_market_outlook"
    "https://www.capitalgroup.com/advisor/insights/articles/weekly-market-commentary.html" "capital_group_weekly_commentary"
)

SKIP_URLS=(
    "https://www.jhinvestments.com/weekly-market-recap#market-moving-news"
)

for (( i=0; i<${#URLS[@]}; i+=2 )); do
    URL="${URLS[$i]}"
    FILENAME_PREFIX="${URLS[$i+1]}"

    SKIP=false
    for skip_url in "${SKIP_URLS[@]}"; do
        if [[ "$URL" == "$skip_url" ]]; then
            echo "Skipping $FILENAME_PREFIX (URL: $URL) as it\"s in the skip list."
            SKIP=true
            break
        fi
    done

    if [ "$SKIP" = true ]; then
        continue
    fi

    echo "Processing $FILENAME_PREFIX..."
    OUTPUT_PATH="$FOLDER_NAME/${FILENAME_PREFIX}.pdf"

    # Attempt direct PDF download first
    if curl -s -L -o "$OUTPUT_PATH" "$URL" && file --mime-type "$OUTPUT_PATH" | grep -q "application/pdf"; then
        echo "$FILENAME_PREFIX PDF downloaded successfully: $OUTPUT_PATH"
    else
        echo "Attempting direct PDF download for $FILENAME_PREFIX..."
        # If direct download fails or is not a PDF, use the Python scraper
        echo "Direct PDF download failed or was not a PDF. Converting webpage to PDF using Enhanced Playwright..."
        python enhanced_pdf_scraper_fixed.py "$URL" "$OUTPUT_PATH"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to process $FILENAME_PREFIX (URL: $URL) with Python scraper."
            rm -f "$OUTPUT_PATH" # Clean up any partial or incorrect file
            continue
        fi
    fi

    # Upload to Gofile
    echo "Uploading $FILENAME_PREFIX PDF to Gofile..."
    UPLOAD_RESPONSE=$(curl -s -F "file=@$OUTPUT_PATH" https://store1.gofile.io/uploadFile)
    UPLOAD_LINK=$(echo "$UPLOAD_RESPONSE" | grep -oP ".*\"downloadPage\":\"\K[^\"]*")

    if [ -n "$UPLOAD_LINK" ] && [ "$UPLOAD_LINK" != "null" ]; then
        echo "$FILENAME_PREFIX PDF uploaded to Gofile. Public download link: $UPLOAD_LINK"
    else
        echo "Error uploading $FILENAME_PREFIX PDF to Gofile. Response: $UPLOAD_RESPONSE"
    fi
done

echo "Automation complete. PDFs are in the $FOLDER_NAME directory."


