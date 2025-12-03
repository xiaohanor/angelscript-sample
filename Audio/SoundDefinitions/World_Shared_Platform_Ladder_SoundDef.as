
UCLASS(Abstract)
class UWorld_Shared_Platform_Ladder_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnPlayerEnteredMidAir(FLadderPlayerEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerEnteredFromWallRun(FLadderPlayerEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerEnteredFromBottom(FLadderPlayerEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerEnteredFromTop(FLadderPlayerEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerExitedByCancelling(FLadderPlayerEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerExitedByJumpingOut(FLadderPlayerEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerExitedFromBottom(FLadderPlayerEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerExitedFromTop(FLadderPlayerEventParams Params){}

	/* END OF AUTO-GENERATED CODE */
}