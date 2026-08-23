import * as crypto from "node:crypto";
import * as pulumi from "@pulumi/pulumi";
import * as cloudflare from "@pulumi/cloudflare";
import * as gcp from "@pulumi/gcp";

const config = new pulumi.Config();

const accountId = config.require("cloudflareAccountId");
const zoneId = config.require("cloudflareZoneId");
const hostname = config.get("hostname") ?? "broadcasts.example.org";
const tunnelName = config.get("tunnelName") ?? "steeple-stream-stakecenter";
const gcpProjectId = config.get("gcpProjectId");
const createGcpProjectServices = config.getBoolean("createGcpProjectServices") ?? false;

const tunnelSecret = new pulumi.Config("secrets").getSecret("tunnelSecret")
  ?? pulumi.secret(crypto.randomBytes(32).toString("base64"));

const tunnel = new cloudflare.ZeroTrustTunnelCloudflared("steeple-stream", {
  accountId,
  name: tunnelName,
  configSrc: "cloudflare",
  tunnelSecret
});

new cloudflare.ZeroTrustTunnelCloudflaredConfig("steeple-stream", {
  accountId,
  tunnelId: tunnel.id,
  config: {
    ingresses: [
      {
        hostname,
        service: "http://127.0.0.1:8080",
        originRequest: {
          connectTimeout: 10,
          httpHostHeader: hostname
        }
      },
      {
        service: "http_status:404"
      }
    ]
  }
});

new cloudflare.DnsRecord("steeple-stream", {
  zoneId,
  name: hostname,
  type: "CNAME",
  content: pulumi.interpolate`${tunnel.id}.cfargotunnel.com`,
  proxied: true,
  ttl: 1
});

// Keep auth in the application for phase one. Cloudflare still owns the outer
// edge controls: Tunnel, DNS, and WAF/rate-limit rules.
new cloudflare.Ruleset("steeple-stream-waf", {
  zoneId,
  name: "Steeple Stream baseline WAF",
  kind: "zone",
  phase: "http_request_firewall_custom",
  rules: [{
    action: "block",
    expression: `(http.host eq "${hostname}" and http.request.uri.path contains "/.")`,
    description: "Block dotfile-style paths"
  }]
});

if (createGcpProjectServices && gcpProjectId) {
  for (const service of [
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iap.googleapis.com"
  ]) {
    new gcp.projects.Service(service.replace(/\./g, "-"), {
      project: gcpProjectId,
      service,
      disableOnDestroy: false
    });
  }
}

export const publicHostname = hostname;
export const tunnelId = tunnel.id;
export const tunnelToken = pulumi.secret(cloudflare.getZeroTrustTunnelCloudflaredTokenOutput({
  accountId,
  tunnelId: tunnel.id
}).token);
export const googleOauthRedirectUri = `https://${hostname}/auth/google/callback`;
