### Common Installation Commands ###
install:  db-create assets-create db-fixtures js perl-deps htaccess
clean: 	  assets-drop search-drop
reload:   db-reload assets-reload update-schema
schema:   update-schema
test:     check

### .js fixture files ###
js: js-qb-templates js-fixtures js-compress
js-fixtures: bin/mk_fixtures.pl
	bin/mk_fixtures.pl
	perl bin/mk-inquiry-json > assets/js_cache/inquiry-titles.js
js-compress: bin/compress-js.pl
	bin/compress-js.pl
	bin/compress-third-party-js.php
	bin/minifyjs public_html/js/pinform.js
js-clean: bin/compress-js.pl
	rm -f public_html/js/air2-compressed.js
js-qb-templates: bin/write-qb-templates-json
	bin/write-qb-templates-json

### .css fixture files ###
css-compress: bin/compress-css.pl
	bin/compress-css.pl
	bin/compress-third-party-css.php

css: css-compress

### perl dependencies ###
# (this just identifies which deps need install via CPAN)
perl-deps: lib/perl/Makefile.PL
	cd lib/perl && perl Makefile.PL

deploy: htaccess js css

### Smoketest ###
smoketest: prep-test assets schema js htaccess check

### Wig and sunglasses ###
disguise: bin/mk_disguise.pl
	bin/mk_disguise.pl
	bin/mk_src_org_cache.pl

### build search indexes ###
search: bin/build-search
	bin/build-search --xml --prune --index
xml:    bin/build-search
	bin/build-search --xml
prune:  bin/build-search
	bin/build-search --prune
indexes: bin/build-search
	bin/build-search --index
search-server-stop: bin/search-server
	bin/search-server stop
search-server-force-stop:
	bin/search-server force_stop
search-server-start: bin/search-server
	bin/search-server start
search-server-restart: bin/search-server
	bin/search-server restart
search-server-check:
	perl bin/check-search-servers
search-drop: search-server-force-stop search-clear
search-clear:
	perl bin/clear-search

### test search builds ###
testsearch: bin/resp2xml.pl
	bin/search-server stop
	perl bin/sources2xml.pl  --from_file=etc/search_ids/test_source_ids
	perl bin/indexer --type=sources
	perl bin/indexer --type=fuzzy_sources
	perl bin/resp2xml.pl     --from_file=etc/search_ids/test_response_ids
	perl bin/indexer --type=responses
	perl bin/indexer --type=fuzzy_responses
	perl bin/inq2xml.pl      --from_file=etc/search_ids/test_inquiry_ids
	perl bin/indexer --type=inquiries
	perl bin/projects2xml.pl --from_file=etc/search_ids/test_project_ids
	perl bin/indexer --type=projects
	perl bin/publicresp2xml.pl --from_file=etc/search_ids/test_public_response_ids
	perl bin/indexer --type=public_responses
	bin/search-server start

### Documentation ###
docs: doc/book/air2.xml
	bin/mk_docs.pl --pdf --html
pdf: doc/book/air2.xml
	bin/mk_docs.pl --pdf
html: doc/book/air2.xml
	bin/mk_docs.pl --html

### Testing Commands ###
prep-test: db-reset db-fixtures db-seeds search-drop xml indexes search-server-check
check: tests/Test.php
	prove -r tests
sane:  bin/data-sanity.pl
	bin/data-sanity.pl

### Schema updates ###
update-schema: schema/000-check.t
	prove -r schema

### Load the geo_lookup table ###
geo-lookup: bin/mk_geo_lookup.pl
	perl bin/mk_geo_lookup.pl

### Some Database create/delete commands ###
db-fixtures: bin/reload-fixture
	php bin/reload-fixture -S ALL
	php bin/reload-fixture -S IptcMaster
	php bin/reload-fixture -S TagMaster
	gunzip -q -c app/fixtures/base/TranslationMap.yml.gz > app/fixtures/base/TranslationMap.yml
	php bin/reload-fixture -S TranslationMap
	rm -f app/fixtures/base/TranslationMap.yml
db-reload: bin/load-db-from-backup
	php bin/load-db-from-backup
db-reset: bin/load-db-from-sql
	php bin/load-db-from-sql
db-seeds: bin/mk-db-seeds
	perl bin/mk-db-seeds

db-create: db-reset

### File asset path create/delete commands ###
assets: assets-create
assets-create: bin/create-asset-paths
	php bin/create-asset-paths
assets-drop: bin/drop-asset-paths
	php bin/drop-asset-paths
assets-reload: bin/load-assets-from-prod
	php bin/load-assets-from-prod
htaccess: bin/create-htaccess
	perl bin/create-htaccess

.PHONY: search install smoketest
