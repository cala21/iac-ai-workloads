"""Rough GPU instance cost estimator for AI workloads (AWS eu-west-1)."""

INSTANCE_COSTS = {
    "g4dn.xlarge":   {"gpu": "T4 (1x)",  "on_demand": 0.736,  "spot_avg": 0.22,  "vram_gb": 16},
    "g4dn.2xlarge":  {"gpu": "T4 (1x)",  "on_demand": 1.123,  "spot_avg": 0.34,  "vram_gb": 16},
    "g4dn.12xlarge": {"gpu": "T4 (4x)",  "on_demand": 4.491,  "spot_avg": 1.35,  "vram_gb": 64},
    "p3.2xlarge":    {"gpu": "V100 (1x)","on_demand": 3.823,  "spot_avg": 1.15,  "vram_gb": 16},
    "p3.8xlarge":    {"gpu": "V100 (4x)","on_demand": 15.292, "spot_avg": 4.59,  "vram_gb": 64},
    "p4d.24xlarge":  {"gpu": "A100 (8x)","on_demand": 32.773, "spot_avg": 9.83,  "vram_gb": 320},
}

def estimate(instance: str, hours_per_day: float = 8, days: int = 22):
    info = INSTANCE_COSTS.get(instance)
    if not info:
        print(f"Unknown instance: {instance}")
        return

    monthly_hours = hours_per_day * days
    on_demand = info["on_demand"] * monthly_hours
    spot = info["spot_avg"] * monthly_hours
    savings = (1 - spot / on_demand) * 100

    print(f"\n{instance} ({info['gpu']}, {info['vram_gb']}GB VRAM)")
    print(f"  On-demand: ${on_demand:,.0f}/month ({hours_per_day}h/day, {days} days)")
    print(f"  Spot:      ${spot:,.0f}/month (~{savings:.0f}% savings)")

if __name__ == "__main__":
    print("GPU Instance Cost Estimates — AWS eu-west-1")
    for instance in INSTANCE_COSTS:
        estimate(instance)
