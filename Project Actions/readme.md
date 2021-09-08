# Project Actions (High-Level Design)

## LM Custom HTTP Integration Setup

- Create new LM Custom HTTP Integration:
  - Add generated webhook URL and authentication settings from Actions app
  - Setup URL and data payloads using example JSON format:

```json
{
  "level": "##LEVEL##",
  "alert_id": "##ALERTID##",
  "group": "##GROUP##",
  "host": "##HOST##",
  "datapoint": "##DATAPOINT##",
  "threshold": "##THRESHOLD##",
  "duration": "##DURATION##",
  "start": "##START##",
  "alert_url": "##ALERTDETAILURL##",
  "service_url": "##URL##",
  "service_description": "##WEBSITEDESCRIPTION##",
  "service_checkpoint": "##WEBSITEDESCRIPTION##",
  "service_group": "##WEBSITEGROUP##",
  "customprop_xyz": "##CUSTOMPROPXYZ##",
  "collector_id": "##SYSTEM.COLLECTORID##",
  "collector_platform": "##SYSTEM.COLLECTORPLATFORM##"
}
```

- Create LM Escalation Chain and assign Actions integration as a stage one recipient and options add additional escalation stages as needed in the event remedation fails to ensure proper notifcations go out
- Create specific alert rules that should trigger the Actions escalation chain (example: WinCitrix datasource for the status of a partuclar service)

## LM Alert process

- Alert is tirggered in LM
- Alert is routed through alert rules table
- If a matching alert is triggered for a rule with the Actions integration assigned as the escalation chain, the alert and JSON payload containing all required info is sent to the Actions Service via authenticated webhook to be processed with whatever scripts/remedation plans are in place for the matching host/datasource/group/etc
- If alert is resolved by the Actions remedaiton plan, the alert clears and not further escalations happen.
- If alert does not resolve in the time specified in the escalation interval, it is escalted to stage two and the recipients/integrations in stage 2 are notified

## LM Action Service

- Using a combination of SaaS services in either AWS or Azure, allow a customer to have a UI to generate an authenticated webhook
- Requests sent to the webhook trigger a lamda/azure funtion to perform some sort of remediation against the alert information being sent via webhook
- The execution of the remediation uses the LM debug command API endpoint to execute the remediation plan aginst the collector that is currently assigned to the device generating the alert and the ID of that collector is sent along with the alery payload information

## Deployment of LM Action Service

- Ideally this would be deployed in a automated fashion through something like a CloudFormation tempalte(aws) or an Resouce template(Azure) to bundle and deploy the service to customers looking to utilize it.

## Considerations

- Due to custom HTTP integrations needing to be publically accessible for LM to reach them, deploying this as a cloud solution makes the most sense as it eliminates the need for the customer to deploy something onprem and open it up to the outside.
- Utilizing the LM Debug API allows us to use already deploy infrastrcutre to perform any remediation as long as we pass the collector id along with the alert payload
- Optionally we can have remediation plans update the active alert with any output for further escalation assistance or for record keeping on remediation status
