import <smmDailyTasks.ash>
int checks;
int failures;
void check(boolean ok, string why) { checks += 1; if (!ok) { failures += 1; print("FAIL: " + why); } }
SmmSpendGap gap(item it, int quantity, int estimate, int limit, boolean ten) {
 SmmSpendGap g;
 g.it = it; g.quantity = quantity; g.estimate = estimate; g.limit = limit; g.toTen = ten;
 return g;
}
void main() {
 SmmSpendGap [int] candidates;
 candidates[0] = gap($item[seal tooth], 10, 10, 100, true);
 candidates[1] = gap($item[helmet turtle], 2, 4000, 10, true);
 candidates[2] = gap($item[spices], 1, 1, 1, false);
 candidates[3] = gap($item[meat paste], 1, 0, 0, true);
 candidates[4] = gap($item[meat stack], 2000000000, 4000000000000, 2000, true);
 SmmSpendGap [int] discovery = smmSpendRankOrder(candidates, false);
 check(count(discovery) == 5 && discovery[0].it == $item[meat paste], "absent historical price does not discard a rank gap");
 check(discovery[1].it == $item[seal tooth] && discovery[2].it == $item[helmet turtle], "historical prices only seed discovery");
 check(discovery[4].it == $item[spices], "even a huge top-ten estimate stays in its priority tier");
 SmmSpendGap [int] quoted = smmSpendRankOrder(candidates, true);
 check(count(quoted) == 4, "unverified zero-price gap cannot authorize a purchase");
 check(quoted[0].it == $item[helmet turtle] && quoted[0].estimate == 20, "verified total cost reverses stale historical order");
 check(quoted[1].it == $item[seal tooth] && quoted[1].estimate == 1000, "quantity multiplies the verified per-copy ceiling");
 check(quoted[2].it == $item[meat stack] && quoted[3].it == $item[spices], "rank tiers do not rely on a fixed numeric offset");
 check(candidates[1].estimate == 4000, "quote ordering leaves discovery evidence intact");
 check(smmSpendRankAffordable(quoted[0], 20), "exact whole-gap budget is allowed");
 check(!smmSpendRankAffordable(quoted[0], 19), "one Meat short cannot authorize a partial gap");
 check(smmSpendRankAffordable(quoted[0], 70), "high historical estimate does not exclude an affordable current quote");
 check(!smmSpendRankAffordable(quoted[0], -1), "negative allowance buys nothing");
 check(!smmSpendRankAffordable(candidates[3], 1000), "unknown ceiling is never affordable");
 SmmSpendGap empty = gap($item[seal tooth], 0, 0, 1, true);
 check(!smmSpendRankAffordable(empty, 1000), "a closed gap is not a purchase");
 int remaining = 70;
 int completed;
 foreach i, g in quoted if (smmSpendRankAffordable(g, remaining)) { remaining -= g.quantity * g.limit; completed += 1; }
 check(completed == 2 && remaining == 49, "quoted order can complete the affordable top-ten gap before a first-place gap");
 SmmSpendGap later = gap($item[seal tooth], 2, 1, 30, true);
 check(smmSpendRankAffordable(later, 70) && !smmSpendRankAffordable(later, 50), "budget changes require whole-gap revalidation before buying");
 SmmSpendGap [int] scan = smmSpendRankScan(discovery, discovery[1].it.to_int());
 check(count(scan) == 5 && scan[0].it == discovery[2].it && scan[4].it == discovery[1].it, "bounded discovery resumes after its last examined item and wraps");
 boolean [item] seen;
 foreach i, g in scan seen[g.it] = true;
 check(count(seen) == 5, "rotation loses or duplicates no candidate");
 scan = smmSpendRankScan(discovery, discovery[4].it.to_int());
 check(scan[0].it == discovery[0].it, "last-item cursor wraps to the first candidate");
 scan = smmSpendRankScan(discovery, 99999999);
 check(scan[0].it == discovery[0].it, "removed cursor item restarts discovery safely");
 clear(candidates);
 quoted = smmSpendRankOrder(candidates, true);
 scan = smmSpendRankScan(candidates, 1);
 check(count(quoted) == 0 && count(scan) == 0, "empty candidate sets remain empty");
 if (failures == 0) print("PASS smmDailyMuseumOrderTest: " + checks + " checks");
 else print("FAILED smmDailyMuseumOrderTest: " + failures + " of " + checks);
}
