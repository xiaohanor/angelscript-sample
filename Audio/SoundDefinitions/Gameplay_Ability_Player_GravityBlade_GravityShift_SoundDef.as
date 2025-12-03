
UCLASS(Abstract)
class UGameplay_Ability_Player_GravityBlade_GravityShift_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UGravityBladeGrappleUserComponent UserGrappleComp;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		UserGrappleComp = UGravityBladeGrappleUserComponent::Get(HazeOwner);
	}

	// UFUNCTION(BlueprintOverride)
	// bool ShouldActivate()
	// {
	// 	return UserGrappleComp.ActiveGrappleData.CanShiftGravity();
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldDeactivate()
	// {
	// 	return !UserGrappleComp.ActiveGrappleData.CanShiftGravity();
	// }

	UFUNCTION(BlueprintPure)
	float GetGravityTransitionDuration() 
	{
		float32 _ = 0.0;
		float32 TimeMax = 0.0;

		UserGrappleComp.GrappleCameraBlend.RotationCurve.GetTimeRange(_, TimeMax);
		return TimeMax;
	}
}