import json
import os
import re
import urllib.parse
import urllib.request
import csv
from urllib.error import HTTPError
from jinja2 import Template
from os.path import exists
import sys
import pathlib

license = "^(LICENSE|LICENCE)($|\.md|\.txt)"
license_specific = "^(LICENSE|LICENCE)([\.-]{})(\.md|\.txt)?"
notice = "NOTICE"

generic_licenses = {
  "Apache-2.0": "https://www.apache.org/licenses/LICENSE-2.0.txt",
  "MIT": "https://spdx.org/licenses/MIT.txt",
  "MIT-0": "https://raw.githubusercontent.com/aws/mit-0/master/MIT-0",
  "ISC": "https://spdx.org/licenses/ISC.txt",
  "BSD-2-Clause": "https://spdx.org/licenses/BSD-2-Clause.txt",
  "BSD-3-Clause": "https://spdx.org/licenses/BSD-3-Clause.txt",
  "MPL-2.0": "https://www.mozilla.org/media/MPL/2.0/index.815ca599c9df.txt",
  "LGPL-2.1-or-later": "https://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt",
  "LGPL-2.1-only": "https://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt",
  "EPL-2.0": "https://www.eclipse.org/org/documents/epl-2.0/EPL-2.0.txt"
}

def extract_license(license_path):
  text_file = open(license_path, "r")

  data = text_file.read()
  
  text_file.close()

  return data

def find_license(path, license_name):
  candidates = []

  for root, directories, files in os.walk(path):
    for name in files:
      if re.search(license_specific.format(license_name), name, re.IGNORECASE):
        return extract_license(os.path.join(root, name))
      if re.search(license, name, re.IGNORECASE):
        return extract_license(os.path.join(root, name))

def fetch_http_license(url):
  try:
    return urllib.request.urlopen(url).read().decode('utf-8')
  except HTTPError as err:
    print('Failed to fetch {}'.format(url))

template = """# Open Source Software Attribution

This software depends on external packages and source code.
The applicable license information is listed below:

{% for package in packages %}----

### {{ package.name }} @{{ package.version }}{% if package.url is not none %} - {{ package.url }}{% endif %}

{{ package.license }}
{% if package.source_url is not none %}
[Source code]({{ package.source_url }}){% endif %}

{% endfor %}
"""

component = sys.argv[1]
base_path = sys.argv[2]
output_file = sys.argv[3]

src_path = '{}/src'.format(base_path)

analyzer_path = '{}/analyzer-result.json'.format(base_path)
go_licenses_path = '{}/licenses.csv'.format(base_path)

packages = []

if exists(analyzer_path):
  f = open(analyzer_path)

  data = json.load(f)

  for i in data['analyzer']['result']['packages']:
    package = i['metadata']

    id = package['id']

    package_manager, group, package_name, version = id.split(':')

    name = ''

    if(group == ''):
      group = 'unknown'
      name = package_name
    else:
      name = '{}:{}'.format(group, package_name)

    url = package['homepage_url']

    source_url = package['source_artifact']['url']

    package_src_path = '{}/{}/{}/{}/{}'.format(src_path, package_manager, urllib.parse.quote_plus(group), urllib.parse.quote_plus(package_name),version)

    license_name = None

    if 'concluded_license' in package:
      license_name = package['concluded_license']
    elif 'spdx_expression' in package['declared_licenses_processed']:
      license_name = package['declared_licenses_processed']['spdx_expression']

    license_text = find_license(package_src_path, license_name)

    if(license_text is None):
      if license_name is not None:
        license_name = package['declared_licenses_processed']['spdx_expression']

        print('Warning: Defaulting to generic {} for {}'.format(license_name, id))

        if license_name in generic_licenses:
          license_url = generic_licenses[license_name]
          license_text = urllib.request.urlopen(license_url).read().decode('utf-8')
        else:
          print('Warning: License {} missing from URL map'.format(license_name))

    if license_text is not None:
      packages.append({"name": name, "url": url, "license": license_text, "version": version, "source_url": source_url})
    else:
      print('Warning: No license entry for {}'.format(id))
elif exists(go_licenses_path):
  with open(go_licenses_path, newline='') as csvfile:
    reader = csv.reader(csvfile, delimiter=',',quotechar='|')
    next(reader, None)
    for row in reader:
      name = row[0]
      version = row[1]
      license_name = row[2]
      license_url = row[3]

      actual_license_url = None

      if 'github.com' in license_url:
        actual_license_url = license_url.replace('blob', 'raw')
      elif 'golang.org/x' in name:
        actual_license_url = 'https://go.dev/LICENSE?m=text'

      if actual_license_url is not None:
        license_text = fetch_http_license(actual_license_url)

        if license_text is None:
          parts = actual_license_url.split('/', 5)
          base_url = '/'.join(parts[:-1])
          license_text = fetch_http_license("{}/raw/{}/LICENSE".format(base_url, version))

        if license_text is None:
          print('Warning: Defaulting to generic {} for {}'.format(license_name, name))

          if license_name in generic_licenses:
            generic_license_url = generic_licenses[license_name]
            license_text = urllib.request.urlopen(generic_license_url).read().decode('utf-8')
          else:
            print('Warning: License {} missing from URL map'.format(license_name))

        packages.append({"name": name, "url": None, "license": license_text, "version": version, "source_url": None})
      else:
        print('Warning: No license entry for {}'.format(name))

else:
  print('Failed to find results file')
  quit()

j2_template = Template(template)

print('Writing results to {}'.format(output_file))

text_file = open(output_file, "w")
n = text_file.write(j2_template.render({"packages": packages}))
text_file.close()

print('Finished!')