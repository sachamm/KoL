// Phase boundaries in the inspected bundle, not upstream value estimates.
import <smmUnrestricted.ash>
import <smmDailyBuyGuard.ash>
string smmGarboEvidencePhase;
string smmGarboEvidenceEpoch;
string smmGarboEvidencePrefix;
SmmRPResource [string] smmGarboEvidencePools;
void smmGarboEvidenceBegin(string phase) {
 smmGuardReady();
 if (smmGarboEvidencePhase != "") abort("smmDaily: nested garbo evidence phase");
 if (!(kDailyGrindNames contains phase) || !phase.starts_with("garbo.")) abort("smmDaily: unknown garbo evidence phase");
 smmGarboEvidenceEpoch = smmDEpoch();
 dailyGrindBegin();
 smmGarboEvidencePools = smmRPLiveResources();
 // The parent ASH interpreter owns the journal; do not use this module's
 // unloaded journal map or overwrite receipts on zero-turn retries.
 int checkpoint = get_property("_smm.daily.journalLines").to_int();
 if (checkpoint <= 0) abort("smmDaily: missing parent checkpoint for garbo evidence");
 smmGarboEvidencePrefix = "smm-garbo-phase-" + my_id() + "-" + today_to_string() + "-" + phase + "-" + checkpoint;
 gGrindReceiptFileOverride = smmGarboEvidencePrefix + "-items.txt";
 if (!map_to_file(smmGarboEvidencePools, smmGarboEvidencePrefix + "-opening.txt"))
  abort("smmDaily: could not write the garbo opening resource evidence");
 smmGarboEvidencePhase = phase;
}
void smmGarboEvidenceEnd(string phase, boolean completed) {
 smmDRequireEpoch(smmGarboEvidenceEpoch);
 if (phase != smmGarboEvidencePhase) abort("smmDaily: garbo evidence phase mismatch");
 SmmRPResource [string] after = smmRPLiveResources();
 int [string,string] outcomes;
 outcomes["@phase","completed"] = completed ? 1 : 0;
 foreach id, before in smmGarboEvidencePools {
  outcomes[id,"beforeKnown"] = before.known ? 1 : 0;
  outcomes[id,"afterKnown"] = after[id].known ? 1 : 0;
  outcomes[id,"beforeCapacity"] = before.remaining;
  outcomes[id,"afterCapacity"] = after[id].remaining;
  // Net capacity can increase through conversions. It is not a gross use
  // count or a causal valuation of each resource.
  outcomes[id,"netCapacityDecrease"] = before.known && after[id].known ? before.remaining-after[id].remaining : 0;
 }
 if (!map_to_file(outcomes, smmGarboEvidencePrefix + "-outcome.txt"))
  abort("smmDaily: could not write the garbo resource outcome evidence");
 dailyGrindEnd(phase, completed);
 smmGarboEvidencePhase = "";
 print("smmDaily: measured " + phase + "; phase cash and signed inventory estimates are not realized profit or isolated paid-turn yield", "blue");
}
