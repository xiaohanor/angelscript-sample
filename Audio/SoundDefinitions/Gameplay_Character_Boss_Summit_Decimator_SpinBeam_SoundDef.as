
UCLASS(Abstract)
class UGameplay_Character_Boss_Summit_Decimator_SpinBeam_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void StopAttack(){}

	UFUNCTION(BlueprintEvent)
	void StartAttack(){}

	UFUNCTION(BlueprintEvent)
	void MoveOnActivation(){}

	UFUNCTION(BlueprintEvent)
	void MoveOnDeactivation(){}

	/* END OF AUTO-GENERATED CODE */

	ASummitDecimatorSpinBeam SpinBeam;

	UFUNCTION(BlueprintEvent)
	void OnCharge() {}

	UFUNCTION(BlueprintEvent)
	void OnStart() {}

	UFUNCTION(BlueprintEvent)
	void OnStop() {}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		SpinBeam = Cast<ASummitDecimatorSpinBeam>(HazeOwner);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Move Alpha"))
	float GetMoveAlpha()
	{
		return SpinBeam.MoveAnimation.GetPosition();
	}

}