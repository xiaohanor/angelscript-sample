
UCLASS(Abstract)
class UVO_Summit_FruitPress_MULTI_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void RollWindupStarted(){}

	UFUNCTION(BlueprintEvent)
	void RollMovementStarted(){}

	UFUNCTION(BlueprintEvent)
	void RollImpact(FRollParams RollParams){}

	UFUNCTION(BlueprintEvent)
	void RollImpactWallKnocback(FRollParams RollParams){}

	UFUNCTION(BlueprintEvent)
	void RollEnded(){}

	UFUNCTION(BlueprintEvent)
	void OnJump(){}

	/* END OF AUTO-GENERATED CODE */

}