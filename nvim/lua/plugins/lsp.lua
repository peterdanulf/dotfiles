return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = function(_, opts)
      -- Ensure servers table exists
      opts.servers = opts.servers or {}

      -- Add Dart LSP (dartls) configuration
      opts.servers.dartls = {
        filetypes = { "dart" },
        root_dir = require("lspconfig.util").root_pattern("pubspec.yaml"),
        settings = {
          dart = {
            completeFunctionCalls = true, -- Auto-complete function calls
            enableSdkFormatter = true, -- Enable Dart formatter
          },
        },
      }

      -- Add Intelephense (PHP LSP) configuration
      opts.servers.intelephense = {
        settings = {
          intelephense = {
            files = {
              maxSize = 1000000, -- Adjust for large files
              exclude = { "**/node_modules/**", "**/vendor/**", "**/.git/**" },
            },
            stubs = {
              "apache", "bcmath", "bz2", "calendar", "com_dotnet", "Core", 
              "curl", "date", "dba", "dom", "enchant", "fileinfo", "filter", "fpm",
              "ftp", "gd", "gettext", "gmp", "hash", "iconv", "imap", "intl", 
              "json", "ldap", "libxml", "mbstring", "mcrypt", "mysql", "mysqli",
              "oci8", "odbc", "openssl", "pcntl", "pcre", "PDO", "pdo_mysql",
              "pdo_pgsql", "pdo_sqlite", "pgsql", "Phar", "posix", "pspell", 
              "readline", "recode", "Reflection", "regex", "session", "shmop", 
              "SimpleXML", "snmp", "soap", "sockets", "sodium", "SPL", "sqlite3",
              "standard", "superglobals", "sysvmsg", "sysvsem", "sysvshm", "tidy",
              "tokenizer", "xml", "xmlreader", "xmlrpc", "xmlwriter", "xsl", "Zend OPcache",
              "zip", "zlib", "wordpress"
            },
            environment = {
              includePaths = {}
            },
            diagnostics = {
              enable = true,
              suppress = {
                "undefinedFunction",
                "undefinedMethod",
                "undefinedClass",
              },
            },
          },
        },
      }
    end,
  },
}
