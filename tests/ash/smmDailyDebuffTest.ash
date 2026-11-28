import <smmConsult.ash>
int checks; int failures;
void check(boolean ok,string why){checks+=1;if(!ok){failures+=1;print("FAIL debuff: "+why);}}
void main(){
 check(!smmDailyCombatItemReady(true,0,100),"closeted/equipped availability is not a physical combat item");
 check(smmDailyCombatItemReady(true,1,0),"reusable owned tool preserves its Museum copy");
 check(!smmDailyCombatItemReady(false,1,0),"protected consumable cannot be queued");
 check(smmDailyCombatItemReady(false,1,1),"owned surplus consumable is eligible");
 item consumable=$item[blue rocket]; item tool=$item[seal tooth];
 check(!consumable.reusable && !consumable.combat_reusable && tool.combat_reusable,"static fixture metadata distinguishes consumables and combat tools");
 item [int] options={consumable,consumable,tool,tool};
 int [item] physical; int [item] spare;
 physical[consumable]=1;spare[consumable]=1;physical[tool]=1;
 item [int] eligible=smmConsultDebuffItems(options,physical,spare);
 check(count(eligible)==3 && eligible[0]==consumable && eligible[1]==tool && eligible[2]==tool,"single consumable copy cannot be promised twice; reusable tools can repeat");
 check(physical[consumable]==1 && spare[consumable]==1,"filter never mutates the caller's counts");
 spare[consumable]=0;physical[tool]=0;
 eligible=smmConsultDebuffItems(options,physical,spare);
 check(count(eligible)==0,"missing secondary tools and protected staggers yield no fabricated actions");
 print((failures==0?"PASS":"FAILED")+" smmDailyDebuffTest: "+checks+" checks");
}
