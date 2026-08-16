.PHONY: app run test clean install

app:
	scripts/bundle.sh

run: app
	open dist/Typestamp.app

test:
	swift test

clean:
	rm -rf .build dist

install: app
	rm -rf /Applications/Typestamp.app
	cp -R dist/Typestamp.app /Applications/
