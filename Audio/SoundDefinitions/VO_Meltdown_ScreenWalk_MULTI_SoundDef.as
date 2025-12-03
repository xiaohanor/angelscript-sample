
UCLASS(Abstract)
class UVO_Meltdown_ScreenWalk_MULTI_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void MeltdownScreenWalkStomp_StartedStomping(){}

	UFUNCTION(BlueprintEvent)
	void MeltdownScreenWalkStomp_StompHit(){}

	UFUNCTION(BlueprintEvent)
	void MeltdownScreenWalkStomp_StoppedStomping(){}

	UFUNCTION(BlueprintEvent)
	void MeltdownScreenWalkMineCart_StompImpact(FMeltdownScreenWalkHookSpot MeltdownScreenWalkHookSpot){}

	UFUNCTION(BlueprintEvent)
	void MeltdownScreenWalkMineCart_StartSparks(FMeltdownScreenWalkHookSpot MeltdownScreenWalkHookSpot){}

	UFUNCTION(BlueprintEvent)
	void MeltdownScreenWalkMineCart_StopSparks(){}

	/* END OF AUTO-GENERATED CODE */
}