
DOCKER_ACCOUNT=sahuamit127

cds-build:
	npm i
	cds build --production

build-dbimage:
	pack build cloud-sf-extension-cap-sample-hana-deployer --path gen/db --builder paketobuildpacks/builder:base
	docker tag cloud-sf-extension-cap-sample-hana-deployer:latest $(DOCKER_ACCOUNT)/cloud-sf-extension-cap-sample-hana-deployer:latest

build-capimage:
	pack build cloud-sf-extension-cap-sample-srv --path gen/srv --builder paketobuildpacks/builder:base
	docker tag cloud-sf-extension-cap-sample-srv:latest $(DOCKER_ACCOUNT)/cloud-sf-extension-cap-sample-srv:latest

build-uiimage:
	docker build --pull --rm -f app/Dockerfile -t $(DOCKER_ACCOUNT)/cloud-sf-extension-cap-sample-approuter:latest ./app

push-images: cds-build build-dbimage build-capimage build-uiimage
	docker push $(DOCKER_ACCOUNT)/cloud-sf-extension-cap-sample-hana-deployer:latest
	docker push $(DOCKER_ACCOUNT)/cloud-sf-extension-cap-sample-srv:latest
	docker push $(DOCKER_ACCOUNT)/cloud-sf-extension-cap-sample-approuter:latest

	