$ACRNAME="aamvadevacr"

az acr build -t hackfest/data-api:1.0 -r $ACRNAME --no-logs ./app/data-api
az acr build -t hackfest/flights-api:1.0 -r $ACRNAME --no-logs ./app/flights-api
az acr build -t hackfest/quakes-api:1.0 -r $ACRNAME --no-logs ./app/quakes-api
az acr build -t hackfest/weather-api:1.0 -r $ACRNAME --no-logs ./app/weather-api
az acr build -t hackfest/service-tracker-ui:1.0 -r $ACRNAME --no-logs ./app/service-tracker-ui


helm upgrade --install data-api ./charts/data-api --namespace aamva
helm upgrade --install quakes-api ./charts/quakes-api --namespace aamva
helm upgrade --install weather-api ./charts/weather-api --namespace aamva
helm upgrade --install flights-api ./charts/flights-api --namespace aamva
helm upgrade --install service-tracker-ui ./charts/service-tracker-ui --namespace aamva

