# metasploit-gvm-plugin

This plugin provides integration with Greenbone Vulnerability Manager (GVM, OpenVAS 10+).

## Usage

Wget nedeed files :

```bash
cd ~/.msf4/plugins/
wget https://raw.githubusercontent.com/evost/gvm-gmp-ruby/master/lib/gvm-gmp.rb
wget https://raw.githubusercontent.com/evost/metasploit-gvm-plugin/master/gvm.rb
```

Type in the Metasploit Framework console:

```ruby
load gvm
gvm_connect admin admin /run/gvmd/gvmd.sock
gvm_version
gvm_help
```
