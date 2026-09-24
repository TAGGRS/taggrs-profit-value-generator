___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.

___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "TAGGRS - POAS Value Generator",
  "categories": ["CONVERSIONS", "ADVERTISING"],
  "description": "Returns product level profit values from the connected product feed trough TAGGRS. Used as the value input for POAS based reporting and bidding.",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "productId",
    "displayName": "Product ID",
    "simpleValueType": true,
    "help": "Enter your TAGGRS Product ID",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "secret",
    "displayName": "API Secret",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "GROUP",
    "name": "group1",
    "displayName": "Ecommerce Data",
    "groupStyle": "ZIPPY_CLOSED",
    "subParams": [
      {
        "type": "TEXT",
        "name": "items",
        "displayName": "Items",
        "simpleValueType": true
      },
      {
        "type": "TEXT",
        "name": "currency",
        "displayName": "Currency",
        "simpleValueType": true
      },
      {
        "type": "TEXT",
        "name": "transaction_id",
        "displayName": "Transaction ID",
        "simpleValueType": true
      },
      {
        "type": "TEXT",
        "name": "value",
        "displayName": "Order Value",
        "simpleValueType": true
      },
      {
        "type": "TEXT",
        "name": "shipping",
        "displayName": "Shipping costs",
        "simpleValueType": true
      },
      {
        "type": "TEXT",
        "name": "tax",
        "displayName": "Tax",
        "simpleValueType": true
      }
    ]
  }
]


___SANDBOXED_JS_FOR_SERVER___

const sendHttpRequest = require('sendHttpRequest');
const encodeUriComponent = require('encodeUriComponent');
const getEventData = require('getEventData');
const JSON = require('JSON');
const logToConsole = require('logToConsole');
const getType = require('getType');
const makeNumber = require('makeNumber');
const Math = require('Math');

const baseUrl = 'https://connect.taggrs.io';

// ---- UI fields -------------------------------------------------------------
const rawProductId = data.productId;
const secret = data.secret;
const returnValue = data.returnValue || 'profit';

if (!rawProductId || !secret) {
  logToConsole('TAGGRS - Error: Product ID or Secret is missing.');
  return undefined;
}

// ---- Collect the items -----------------------------------------------------
// Priority: explicit UI field > items from the incoming event data.
let rawItems = data.items;

if (getType(rawItems) === 'string') {
  rawItems = JSON.parse(rawItems);
}
if (getType(rawItems) !== 'array') {
  rawItems = getEventData('items');
}
if (getType(rawItems) !== 'array' || rawItems.length === 0) {
  logToConsole('TAGGRS - Error: No items found to send.');
  return undefined;
}

const items = [];
for (let i = 0; i < rawItems.length; i++) {
  const src = rawItems[i];

  if (getType(src) === 'object') {
    const itemId = src.item_id || src.id || src.sku;

    if (itemId) {
      const price = makeNumber(src.price);
      const quantity = makeNumber(src.quantity);

      items.push({
        item_id: itemId,
        item_name: src.item_name || src.name,
        // NaN !== NaN, so this falls back cleanly on missing or invalid values
        price: price === price ? price : 0,
        quantity: quantity === quantity ? quantity : 1
      });
    }
  }
}

if (items.length === 0) {
  logToConsole('TAGGRS - Error: Items array contained no usable item_id values.');
  return undefined;
}

// ---- Build the payload -----------------------------------------------------
const payload = {
  event_name: getEventData('event_name'),
  currency: data.currency || getEventData('currency') || 'EUR',
  transaction_id: data.transactionId || getEventData('transaction_id'),
  value: data.value || getEventData('value') || 0,
  shipping: data.shipping || getEventData('shipping') || 0,
  tax: data.tax || getEventData('tax') || 0,
  items: items
};

const productId = encodeUriComponent(rawProductId);
const url = baseUrl + '/v1/products/' + productId + '/ecommerce/profit-tracking/calculate';

const requestOptions = {
  method: 'POST',
  headers: {
    'X-Secret': secret,
    'Content-Type': 'application/json'
  },
  timeout: 5000
};

logToConsole('TAGGRS - Sending ' + items.length + ' item(s) for product ' + rawProductId);

// ---- Single request --------------------------------------------------------
return sendHttpRequest(url, requestOptions, JSON.stringify(payload)).then(response => {
  if (response.statusCode < 200 || response.statusCode >= 300) {
    logToConsole('TAGGRS - Error (Status: ' + response.statusCode + '): ' + response.body);
    return undefined;
  }

  const body = JSON.parse(response.body);

  if (getType(body) !== 'object') {
    logToConsole('TAGGRS - Error: Could not parse response body.');
    return undefined;
  }

  logToConsole('TAGGRS - Response received:', body);

  // Whole response object
  if (returnValue === 'raw_feed_data') {
    return body;
  }

  // Per item detail: [{item_id, matched, unit_profit, line_profit, components}, ...]
  if (returnValue === 'items') {
    return body.items;
  }

  if (returnValue === 'unmatched_item_ids') {
    return body.unmatched_item_ids;
  }

  // Everything else comes from totals:
  // profit | item_count | matched_count | unmatched_count | quantity
  const totals = body.totals;

  if (getType(totals) !== 'object') {
    logToConsole('TAGGRS - Error: No totals object in response.');
    return undefined;
  }

  const value = totals[returnValue];

  if (getType(value) !== 'number') {
    logToConsole('TAGGRS - Error: "' + returnValue + '" not found in totals.');
    return undefined;
  }

  const rounded = Math.round(value * 100) / 100;
  logToConsole('TAGGRS - Returning ' + returnValue + ':', rounded);
  return rounded;
}).catch(error => {
  logToConsole('TAGGRS - Network error:', error);
  return undefined;
});


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "send_http",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "urls",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "https://connect.taggrs.io/*"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_event_data",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keyPatterns",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "currency"
              },
              {
                "type": 1,
                "string": "transaction_id"
              },
              {
                "type": 1,
                "string": "items"
              },
              {
                "type": 1,
                "string": "event_name"
              },
              {
                "type": 1,
                "string": "value"
              },
              {
                "type": 1,
                "string": "tax"
              },
              {
                "type": 1,
                "string": "shipping"
              }
            ]
          }
        },
        {
          "key": "eventDataAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios: []


___NOTES___

Created on 9/24/2026, 10:27:09 AM


