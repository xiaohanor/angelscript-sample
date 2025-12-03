
UCLASS(Abstract)
class UCharacter_Boss_Summit_RubyKnight_Sword_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnSingleSlashTelegraph(FSummitKnightPlayerParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnSingleSlashDirectHitBoth(){}

	UFUNCTION(BlueprintEvent)
	void OnSingleSlashDirectHit(FSummitKnightPlayerParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnSingleSlashNearHit(FSummitKnightPlayerParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnSingleSlashShockwaveHit(FSummitKnightPlayerParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnSingleSlashMiss(FSummitKnightPlayerParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnSingleSlashAborted(){}

	UFUNCTION(BlueprintEvent)
	void OnSpinningSlashTelegraph(){}

	UFUNCTION(BlueprintEvent)
	void OnSpinningSlashStart(FSummitKnightMeleeShockwaveParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnSpinningSlashStartLoop(){}

	UFUNCTION(BlueprintEvent)
	void OnSpinningSlashEnd(){}

	UFUNCTION(BlueprintEvent)
	void OnSpinningSlashAborted(){}

	UFUNCTION(BlueprintEvent)
	void OnSlamTelegraph(){}

	UFUNCTION(BlueprintEvent)
	void OnSlamDirectHitBoth(){}

	UFUNCTION(BlueprintEvent)
	void OnSlamDirectHit(FSummitKnightPlayerParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnSlamShockwaveHit(FSummitKnightPlayerParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnSlamMiss(){}

	UFUNCTION(BlueprintEvent)
	void OnSlamImpact(FSummitKnightBladeImpactParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnSlamAggroTelegraph(){}

	UFUNCTION(BlueprintEvent)
	void OnSingleSlashImpact(){}

	UFUNCTION(BlueprintEvent)
	void OnDualSlashFirstTelegraph(FSummitKnightPlayerParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnDualSlashSecondTelegraph(FSummitKnightPlayerParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnDualSlashFirstDirectHitBoth(){}

	UFUNCTION(BlueprintEvent)
	void OnDualSlashSecondDirectHitBoth(){}

	UFUNCTION(BlueprintEvent)
	void OnDualSlashFirstDirectHit(FSummitKnightPlayerParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnDualSlashSecondDirectHit(FSummitKnightPlayerParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnDualSlashFirstImpact(){}

	UFUNCTION(BlueprintEvent)
	void OnDualSlashSecondImpact(){}

	UFUNCTION(BlueprintEvent)
	void OnSlamStartSwordPullout(FSummitKnightBladeImpactParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnSmashGroundAggroFirstImpact(){}

	UFUNCTION(BlueprintEvent)
	void OnSmashGroundAggroFinalImpact(){}

	UFUNCTION(BlueprintEvent)
	void OnSmashGroundAggroFirstTelegraph(){}

	UFUNCTION(BlueprintEvent)
	void OnSmashGroundAggroFinalTelegraph(){}

	UFUNCTION(BlueprintEvent)
	void OnSmashGroundAborted(){}

	/* END OF AUTO-GENERATED CODE */

	AAISummitKnight Knight;
	
	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Knight = Cast<AAISummitKnight>(HazeOwner);
	}
}