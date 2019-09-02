CHART_NAME=$(shell cat chart/webapp/Chart.yaml | yq -r .name)
CHART_VERSION=$(shell cat chart/webapp/Chart.yaml | yq -r .version)
CHART_BUCKET=my-s3-bucket

APP_VERSION ?= $(shell cat chart/webapp/Chart.yaml | yq -r .appVersion)

docker:
	docker build -t gkg/webapp:${APP_VERSION}
	docker tag gkg/webapp:${APP_VERSION} gkg/webapp:latest

dockerpush:
	docker push gkg/webapp:${APP_VERSION}
	docker push gkg/webapp:latest

compile:
	helm package chart/webapp

upload:
	aws s3 cp ${CHART_NAME}-${CHART_VERSION}.tgz s3://${CHART_BUCKET}/packages
	aws s3 cp values/dev.yaml s3://${CHART_BUCKET}/packagevalues/${CHART_NAME}/dev.yaml
	aws s3 cp values/prod.yaml s3://${CHART_BUCKET}/packagevalues/${CHART_NAME}/prod.yaml

triggerdocker:
	curl -L -vvv -X POST \
		-k \
		-H "content-type: application/json" http://myspinnaker.com:8084/webhooks/webhook/webhookName \
		-d '{"artifacts":[{"type": "docker/image", "name": "${CHART_NAME}", "reference": "gkg/webapp:${APP_VERSION}", "kind": "docker"}]}'

triggerchart:
	curl -L -vvv -X POST \
		-k \
		-H "content-type: application/json" http://myspinnaker.com:8084/webhooks/webhook/webhookName \
		-d '{"artifacts":[{"type": "s3/object", "name": "s3://${CHART_BUCKET}/packages/${CHART_NAME}-${CHART_VERSION}.tgz", "reference": "s3://${CHART_BUCKET}/packages/${CHART_NAME}-${CHART_VERSION}.tgz", "kind": "s3"}]}'