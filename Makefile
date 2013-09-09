### Common Installation Commands ###
install:  db-create assets-create db-fixtures js perl-deps budgethero
clean: 	  db-drop assets-drop
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
	bin/minifyjs public_html/js/pinform.js
js-clean: bin/compress-js.pl
	rm -f public_html/js/air2-compressed.js
js-qb-templates: bin/write-qb-templates-json
	bin/write-qb-templates-json

### .css fixture files ###
css-compress: bin/compress-css.pl
	bin/compress-css.pl

css: css-compress

### perl dependencies ###
# (this just identifies which deps need install via CPAN)
perl-deps: lib/perl/Makefile.PL
	cd lib/perl && perl Makefile.PL

deploy: js css

### Smoketest ###
smoketest: assets schema js budgethero search-server-restart check html

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
search-server-start: bin/search-server
	bin/search-server start
search-server-restart: bin/search-server
	bin/search-server restart

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
db: db-create
db-create: bin/create-db
	php bin/create-db
db-drop: bin/drop-db
	php bin/drop-db
db-fixtures: bin/reload-fixture
	php bin/reload-fixture ALL -S
	php bin/reload-fixture IptcMaster -S
	php bin/reload-fixture TagMaster -S
db-reload: bin/load-db-from-backup
	php bin/load-db-from-backup

### File asset path create/delete commands ###
assets: assets-create
assets-create: bin/create-asset-paths
	php bin/create-asset-paths
assets-drop: bin/drop-asset-paths
	php bin/drop-asset-paths
assets-reload: bin/load-assets-from-prod
	php bin/load-assets-from-prod

#### querymaker dev #####
qm-prep:
	perl lib/dbconv/qm/001-set-srs-fb-approved-flag.pl
	perl lib/dbconv/qm/002-set-public-flags.pl
	perl lib/dbconv/qm/003-set-librarius-public.pl
	perl lib/dbconv/qm/004-contributor-questions.pl
	perl lib/dbconv/qm/005-question_resp_opts.pl
	perl lib/dbconv/qm/006-inquiry-author.pl
	perl lib/dbconv/qm/007-inquiry-watcher.pl
	perl lib/dbconv/qm/008-thanks-msg.pl
	perl lib/dbconv/qm/009-file-ques_resp_type.pl

#### budget hero ####
budgethero:
	perl bin/mk-budgethero-ini > etc/budgethero.ini

