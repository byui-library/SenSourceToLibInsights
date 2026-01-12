# API Settings

Use APIs to process and display LibWizard content outside your system. To use an Endpoint, you must first create an access token in the **API Authentication** tab for each application you intend to create.

---

## Authentication via OAuth

The LibWizard API uses **OAuth 2.0** for authentication and supports the **Client Credentials** grant type. 

### Best Practices
* **Server-to-Server:** Ideally, your client applications should communicate with your own server, which then communicates with the LibWizard API. This keeps your `client_id` and `client_secret` out of the public domain.
* **CORS:** Cross-origin resource sharing is allowed from any domain. For read-only applications, you can have the client communicate directly with the API, though this exposes your credentials.
* **Security:** It is strongly advised to keep credentials private for applications with **write permissions**. Always access the API via **HTTPS**.

---

## Obtaining an Access Token

**Endpoint:** `https://byui.libwizard.com/api/v1/oauth/token`

**Required POST Fields:**
* `client_id`
* `client_secret`
* `grant_type`: `client_credentials`

---

## Authorizing your API Requests

Once you have an access token, send it via the `Authorization` header. The method (GET/POST) will vary based on the specific endpoint.

**Example Request:**
```http
GET /api/v1/public/forms
Host: [https://byui.libwizard.com/](https://byui.libwizard.com/)
Authorization: Bearer ACCESSTOKEN