# RESheeT

Create RESTful API from Google Sheet.

## What's this?

For prototypes, we usually need some simple DB and WEB API to CRUD the data.
While it is possible to provide real DBMS, isn't it great if we can simply use Google Sheet for storing and serving the data?

Using Google Sheet has following benefits.

- Easy to create table. Just add a sheet and define header column, and you are ready.
- Easy to modify the data. Especially for a teammate who isn't familliar with DBMS.
- You can use formulars for advanced usecases.

## Getting Started

### To create an account

1. Create a Service Account on [Google Developers Console](https://console.developers.google.com).
1. Download the access key of the account in JSON format.
1. Enable Google Sheet API on the console.
1. Create a spreadsheet on Google Sheet.
1. Share the spreadsheet to the account with read & write permissions.

### To run the server

1. Encode the access key in Base64
    - `ruby TODO`
1. Define environment variables.
    - `RESHEET_SPREADSHEET_ID` : The ID of the spreadsheet
    - `RESHEET_CREDENTIALS` : The access key
    - `RESHEET_API_KEY` : TODO
