{...}: {
  flake.nixosModules.network-tuning = {...}: {
    # BBR + fq: keeps latency low under load and copes better with lossy Wi-Fi
    # than cubic + fq_codel.
    boot.kernelModules = ["tcp_bbr"];
    boot.kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";

      # Recover from PMTU black holes (Tailscale, eduroam) instead of stalling.
      "net.ipv4.tcp_mtu_probing" = 1;
      "net.ipv4.tcp_fastopen" = 3;
      # Don't drop back to slow start on idle keep-alive connections.
      "net.ipv4.tcp_slow_start_after_idle" = 0;

      # Room for high bandwidth-delay links; autotuning still starts small.
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_max" = 16777216;
      "net.ipv4.tcp_rmem" = "4096 131072 16777216";
      "net.ipv4.tcp_wmem" = "4096 131072 16777216";
    };

    # Nothing here needs the network before login; this only delays boot.
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
