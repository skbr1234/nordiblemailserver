#!/bin/bash
set -e

# Wait for the SQLite database to be ready
sleep 2

# Skip if already initialized
if pdnsutil list-zone nordiblemailserver.test >/dev/null 2>&1; then
    echo "Zone nordiblemailserver.test already exists; skipping init."
    exit 0
fi

# Create the zone with default SOA + NS
pdnsutil create-zone nordiblemailserver.test ns1.nordiblemailserver.test
pdnsutil set-kind nordiblemailserver.test native

# Replace the default SOA with our own
pdnsutil replace-rrset nordiblemailserver.test '' SOA 'ns1.nordiblemailserver.test. admin.nordiblemailserver.test. 2024010101 3600 900 604800 86400'

# Add basic records
pdnsutil add-record nordiblemailserver.test 'ns1' A '127.0.0.1'
pdnsutil add-record nordiblemailserver.test '' A '127.0.0.1'
pdnsutil add-record nordiblemailserver.test '' MX '10 mail.nordiblemailserver.test.'
pdnsutil add-record nordiblemailserver.test 'mail' A '127.0.0.1'

# Add a sample TLSA record
# Usage=3 (DANE-EE), Selector=1 (SubjectPublicKeyInfo), Matching=1 (SHA-256)
pdnsutil add-record nordiblemailserver.test '_25._tcp.mail' TLSA '3 1 1 0000000000000000000000000000000000000000000000000000000000000000'

# Import static TSIG key for RFC2136 dynamic updates
# Key: nordiblemailserver-update-key / HMAC-SHA256
# Base64 secret: c3RhbHdhcnQtdGVzdC10c2lnLXNlY3JldC1rZXkxMjM0NTY3ODkw
pdnsutil import-tsig-key nordiblemailserver-update-key hmac-sha256 'c3RhbHdhcnQtdGVzdC10c2lnLXNlY3JldC1rZXkxMjM0NTY3ODkw'
pdnsutil activate-tsig-key nordiblemailserver.test nordiblemailserver-update-key primary
pdnsutil set-meta nordiblemailserver.test TSIG-ALLOW-DNSUPDATE nordiblemailserver-update-key
pdnsutil set-meta nordiblemailserver.test ALLOW-DNSUPDATE-FROM '0.0.0.0/0'


echo "PowerDNS zone setup complete."
echo "TSIG key name:      nordiblemailserver-update-key"
echo "TSIG algorithm:     hmac-sha256"
echo "TSIG secret (b64):  c3RhbHdhcnQtdGVzdC10c2lnLXNlY3JldC1rZXkxMjM0NTY3ODkw"
