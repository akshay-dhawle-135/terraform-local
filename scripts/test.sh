export AWS_PROFILE=eventbridge
export AWS_ENDPOINT_URL=http://localhost:4566
export EVENT_BUS_NAME=test-bus
export CONNECTION_NAME=test-connection
export AUTH_ENDPOINT=""
export API_DESTINATION=my-api-destination
export API_DESTINATION_INVOCATION_ENDPOINT=""
export RULE=my-rule
export CLIENT_ID=""
export CLIENT_SECRET=""
export SCOPE=""
export AWS_REGION="us-east-1"

echo "creating role"
awslocal iam create-role \
    --role-name eventbridge-invocation-role \
    --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"events.amazonaws.com"},"Action":"sts:AssumeRole"}]}'

echo "creating policy"
awslocal iam create-policy \
    --policy-name eventbridge-invocation-policy \
    --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"events:InvokeApiDestination","Resource":"*"}]}'

echo "attaching policy to role"
awslocal iam attach-role-policy \
    --role-name eventbridge-invocation-role \
    --policy-arn arn:aws:iam::000000000000:policy/eventbridge-invocation-policy

# Create Event Bus
echo "creating event bus"
awslocal events create-event-bus \
    --name $EVENT_BUS_NAME \
    --description "Description of my event bus"


# Create Connection
echo "creating connection"
awslocal events create-connection \
    --name $CONNECTION_NAME \
    --authorization-type OAUTH_CLIENT_CREDENTIALS \
    --auth-parameters '{"OAuthParameters": {"AuthorizationEndpoint": "$AUTH_ENDPOINT", "HttpMethod": "POST", "ClientParameters": {"ClientID": "$CLIENT_ID", "ClientSecret": "$CLIENT_SECRET"}, "OAuthHttpParameters": {"BodyParameters": [{"Key": "grant_type", "Value": "client_credentials"}, {"Key": "scope", "Value": "$SCOPE"}]}}}'

# Create API Destination
echo "creating API connection"
awslocal events create-api-destination \
    --name $API_DESTINATION \
    --connection-arn arn:aws:events:$AWS_REGION:000000000000:connection/$CONNECTION_NAME \
    --http-method GET \
    --invocation-endpoint $API_DESTINATION_INVOCATION_ENDPOINT \
    --invocation-rate-limit-per-second 100

# Create Rule
echo "creating rule"
awslocal events put-rule \
    --name $RULE \
    --event-bus-name $EVENT_BUS_NAME \
    --event-pattern '{"detail-type": ["identity-created"]}'

echo "creating log group"
awslocal logs create-log-group --log-group-name my-log-group

echo "creating log stream"
awslocal logs create-log-stream --log-group-name my-log-group --log-stream-name my-log-stream

# Put Targets
echo "adding targets"
awslocal events put-targets \
    --rule $RULE \
    --event-bus-name $EVENT_BUS_NAME \
    --targets "Id"="1","Arn"="arn:aws:events:$AWS_REGION:000000000000:api-destination/$API_DESTINATION","RoleArn"="arn:aws:iam::000000000000:role/eventbridge-invocation-role"

awslocal events put-targets \
    --rule my-rule \
    --event-bus-name $EVENT_BUS_NAME \
    --targets "Id"="2","Arn"="arn:aws:logs:us-east-1:000000000000:log-group/my-log-group","RoleArn"="arn:aws:iam::000000000000:role/eventbridge-logs-role"

echo "testing: publishing event details."
awslocal events put-events \
    --entries '[{
        "Source": "1",
        "DetailType": "identity-created",
        "Detail": "{\"name\":\"akshay\", \"key2\":\"value2\"}",
        "EventBusName": "$EVENT_BUS_NAME"
    }]'


awslocal events list-event-buses
awslocal events list-connections
aws events list-rules --event-bus-name $EVENT_BUS_NAME
