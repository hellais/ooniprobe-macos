class Ooniprobe < Formula
  include Language::Python::Virtualenv

  desc "Network interference detection tool"
  homepage "https://ooni.org/"
  url "https://github.com/ooni/probe-cli/archive/v3.0.9.tar.gz"
  sha256 "1910d8042bf92528ba233ef874e128e2960ab2e3e9b7081367529e7ca421f055"
  license "BSD-2-Clause"
  revision 3

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = HOMEBREW_CACHE/"go_cache"
    (buildpath/"src/github.com/ooni/probe-cli").install buildpath.children

    cd "src/github.com/ooni/probe-cli" do
      system "go", "build", "-o", bin/"ooniprobe", "./cmd/ooniprobe"

      prefix.install_metafiles
    end

    (HOMEBREW_PREFIX/"etc/ooniprobe-daily-config.json").write <<-EOS.undent
    {
      "_version": 3,
      "_informed_consent": true,
      "sharing": {
        "include_ip": false,
        "include_asn": true,
        "upload_results": true
      },
      "nettests": {
        "websites_url_limit": 100,
        "websites_enabled_category_codes": [
          "ALDR",
          "ANON",
          "COMM",
          "COMT",
          "CTRL",
          "CULTR",
          "DATE",
          "ECON",
          "ENV",
          "FILE",
          "GAME",
          "GMB",
          "GOVT",
          "GRP",
          "HACK",
          "HATE",
          "HOST",
          "HUMR",
          "IGO",
          "LGBT",
          "MILX",
          "MISC",
          "MMED",
          "NEWS",
          "POLR",
          "PORN",
          "PROV",
          "PUBH",
          "REL",
          "SRCH",
          "XED"
        ]
      },
      "advanced": {
        "use_domain_fronting": false,
        "send_crash_reports": true,
        "collect_usage_stats": true,
        "collector_url": "",
        "bouncer_url": "https://bouncer.ooni.io"
      }
    }
    EOS
  end

  plist_options startup: "true", manual: "ooniprobe --config \"#{HOMEBREW_PREFIX}/etc/ooniprobe-daily-config.json\" run"

  def plist
    <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>Label</key>
        <string>#{plist_name}</string>

        <key>KeepAlive</key>
        <false/>
        <key>RunAtLoad</key>
        <true/>

        <key>EnvironmentVariables</key>
        <dict>
          <key>PATH</key>
          <string>#{HOMEBREW_PREFIX}/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
        </dict>

        <key>Program</key>
        <string>#{opt_bin}/ooniprobe</string>
        <string>run</string>
        <key>ProgramArguments</key>
        <array>
            <string>--config "#{HOMEBREW_PREFIX}/etc/ooniprobe-daily-config.json"</string>
            <string>--batch</string>
            <string>run</string>
        </array>

        <key>StartInterval</key>
        <integer>3600</integer>

        <key>StandardErrorPath</key>
          <string>/dev/null</string>
        <key>StandardOutPath</key>
          <string>/dev/null</string>
        <key>WorkingDirectory</key>
          <string>#{opt_prefix}</string>
    </dict>
    </plist>
    EOS
  end

  test do
    (testpath/"config.json").write <<-EOS.undent
    {
      "_version": 3,
      "_informed_consent": true,
      "sharing": {
        "include_ip": false,
        "include_asn": true,
        "upload_results": false
      },
      "nettests": {
        "websites_url_limit": 1,
        "websites_enabled_category_codes": []
      },
      "advanced": {
        "send_crash_reports": true,
        "collect_usage_stats": true
      }
    }
    EOS

    mkdir_p "#{testpath}/ooni_home"
    ENV["OONI_HOME"] = "#{testpath}/ooni_home"
    system bin/"ooniprobe", "--config", testpath/"config.json", "run", "websites"
  end
end
