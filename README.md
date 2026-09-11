# TAGGRS - Profit Value Generator
 
A Google Tag Manager variable template that returns the profit value of a transaction, based on product level data from a connected product feed trough TAGGRS.
 
Use it as the value input for Profit tracking (POAS) reporting and bidding, instead of sending revenue.
 
## What it does
 
The variable matches each item in the ecommerce event against the product feed connected through TAGGRS, looks up the profit value per product, and returns the combined profit for the current transaction. The returned value can be passed to any tag that accepts a numeric value, such as Google Ads conversion tags, Meta CAPI, or GA4.
 
## Requirements

- A TAGGRS account with an active product feed connection
- Purchase event data containing product IDs that match the feed

## Configuration
 
| Field | Required | Description |
| --- | --- | --- |
| Product ID | Yes | The product identifier found in your TAGGRS dashboard |
| API Secret | Yes | Generated in the profit tracking tool in your TAGGRS dashboard |
| Items | Yes | The items array of the purchase. Reads from the event data automatically when left empty |
| Currency | No | The currency of the transaction. Reads from the event data automatically when left empty |
| Transaction ID | Yes | The unique identifier of the transaction. Reads from the event data automatically when left empty |
 
## Installation
 
1. Download `template.tpl` from this repository.
2. In Google Tag Manager, go to **Templates** > **Variable Templates** > **New**.
3. Open the menu in the top right corner and choose **Import**.
4. Select the downloaded `template.tpl` file and save.

## Usage
 
1. Create a new variable using this template.
2. Enter your Product ID and API Secret from the TAGGRS dashboard. Fill in Items, Currency and Transaction ID or leave them empty to read from the event data.
3. Reference the variable in the value field of your conversion tag.
4. Verify the output in Preview mode before publishing.