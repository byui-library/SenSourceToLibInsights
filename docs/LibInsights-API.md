# LibInsights API Documentation

See **Manage API Authentication** tab for generating `access_token`.

---

## Base URL

The base URL for all POST, PUT and GET API endpoints:

```
https://byui.libinsight.com/v1.0
Authorization: Bearer access_token
```

> **Note:** Previous POST base URL below is still supported until the end of 2025 (please make sure to update your POST API references):
> ```
> https://byui.libinsight.com/post/v1.0
> Authorization: Bearer access_token
> ```

---

## Auth

Information about Authorization

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/oauth/token` | Obtain an Access Token |

---

## Custom or Shared Dataset

Custom or Shared Dataset GET and POST API

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/custom-dataset/{id}/fields` | Return Custom Dataset Fields |
| GET | `/shared-dataset/{id}/fields` | Return Shared Dataset Fields |
| GET | `/custom-dataset/{id}/data-grid` | Returns the Custom or Shared Dataset records |
| POST | `/custom-dataset/{id}/save` | Add multiple records to Custom Dataset |
| POST | `/shared-dataset/{id}/save` | Add multiple records to Shared Dataset |

---

## Gate Count Dataset

Gate Count Dataset GET and POST API

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/gate-count/{id}/libraries` | Return Gate Count Dataset Libraries |
| GET | `/gate-count/{id}/overview` | Returns Gate Count Dataset Overview Stats |
| GET | `/gate-count/{id}/trends` | Returns Gate Count Dataset Trends Stats |
| **POST** | **`/gate-count/{id}/save`** | **Add multiple records to Gate Count Dataset** |

---

## Acquisitions Dataset

Acquisitions Dataset GET API

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/acquisitions/{id}/overview` | Returns Acquisitions Dataset Overview Stats |
| GET | `/acquisitions/{id}/groups` | Returns Acquisitions Dataset Groups Stats |
| GET | `/acquisitions/{id}/classifications` | Returns Acquisitions Dataset Classification Stats |
| GET | `/acquisitions/{id}/popular` | Returns Acquisitions Dataset Popular Stats |
| GET | `/acquisitions/{id}/trends` | Returns Acquisitions Dataset Trends Stats |

---

## Circulation Dataset

Circulation Dataset GET API

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/circulation/{id}/overview` | Returns Circulation Dataset Overview Stats |
| GET | `/circulation/{id}/groups` | Returns Circulation Dataset Groups Stats |
| GET | `/circulation/{id}/classifications` | Returns Circulation Dataset Classification Stats |
| GET | `/circulation/{id}/popular` | Returns Circulation Dataset Popular Stats |
| GET | `/circulation/{id}/trends` | Returns Circulation Dataset Trends Stats |

---

## Counts/Aggregate Dataset

Counts/Aggregate Dataset GET API

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/counts-aggregate/{id}/fields` | Returns Counts/Aggregate Dataset Fields metadata |
| GET | `/counts-aggregate/{id}/overview` | Returns Counts/Aggregate Dataset Overview Stats |
| GET | `/counts-aggregate/{id}/field-aggregates` | Returns Counts/Aggregate Dataset Field Aggregates Stats |
| GET | `/counts-aggregate/{id}/distribution` | Returns Counts/Aggregate Dataset Distribution Stats |
| GET | `/counts-aggregate/{id}/trends` | Returns Counts/Aggregate Dataset Trends Stats |

---

## Interlibrary Loans Dataset

Interlibrary Loans Dataset GET API

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/interlibrary-loan/{id}/overview` | Returns Interlibrary Loans Dataset Overview Stats |
| GET | `/interlibrary-loan/{id}/details` | Returns Interlibrary Loans Dataset Details Stats |

---

## Reference Dataset

Reference Dataset GET API

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/reference/{id}/overview` | Returns Reference Dataset Overview Stats |
| GET | `/reference/{id}/trends` | Returns Reference Dataset Trends Stats |

---

## Calendaring Dataset

Calendaring Dataset GET API

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/calendar/{id}/overview` | Returns Calendaring Dataset Overview Stats |
| GET | `/calendar/{id}/trends` | Returns Calendaring Dataset Trends Stats |

---

## LibGuides Dataset

LibGuides Dataset GET API

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/libguides/{id}/overview` | Returns LibGuides Dataset Overview Stats |
| GET | `/libguides/{id}/guides` | Returns LibGuides Dataset Guides Stats |
| GET | `/libguides/{id}/trends` | Returns LibGuides Dataset Trends Stats |

---

## LibWizard Dataset

LibWizard Dataset GET API

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/libwizard/{id}/forms` | Returns LibWizard Dataset Forms |
| GET | `/libwizard/{id}/overview` | Returns LibWizard Dataset Overview Stats |
| GET | `/libwizard/{id}/distribution` | Returns LibWizard Dataset Distribution Stats |
| GET | `/libwizard/{id}/trends` | Returns LibWizard Dataset Trends Stats |

---

## Google Analytics Dataset

Google Analytics Dataset GET API

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/google-analytics/{id}/overview` | Returns Google Analytics Dataset Overview Stats |
| GET | `/google-analytics/{id}/trends` | Returns Google Analytics Dataset Trends Stats |

---

## Finance Dataset

Finance Dataset GET API

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/finance/{id}/categories` | Returns Finance Dataset Categories |
| GET | `/finance/{id}/overview` | Returns Finance Dataset Overview Stats |
| GET | `/finance/{id}/trends` | Returns Finance Dataset Trends Stats |
| GET | `/finance/{id}/line-items` | Returns Finance Dataset Line Items Stats |

---

## E-Resources Dataset

E-Resources Dataset GET, PUT and POST API

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/e-resources/{id}/platforms` | Returns E-Resources Dataset Platforms |
| GET | `/e-resources/{id}/overview` | Returns E-Resources Dataset Platforms Overview |
| GET | `/e-resources/{id}/top-use-titles` | Returns E-Resources Dataset Top Use Titles by Platform (Top 100) |
| GET | `/e-resources/{id}/duplicate-titles` | Returns E-Resources Dataset Duplicate Titles across Platforms by Data Type |
| GET | `/e-resources/{id}/titles/{title_id}` | Returns E-Resources Dataset Title Usage across Platforms by Data Type |
| GET | `/e-resources/{id}/sushi-schedules` | Returns E-Resources Dataset SUSHI Schedules |
| PUT | `/e-resources/{id}/sushi-schedules` | Update E-Resources Dataset SUSHI Schedules Status |
| POST | `/e-resources/platforms` | Add multiple platforms for use in E-Resources Management |
| POST | `/e-resources/sushi-providers` | Add multiple SUSHI Providers for use in E-Resources Management |
