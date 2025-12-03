
UCLASS(Abstract)
class UWorld_Skyline_Highway_Interactable_CargoScanner_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UFauxPhysicsTranslateComponent FauxPhysicsTranslate;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		FauxPhysicsTranslate = UFauxPhysicsTranslateComponent::Get(HazeOwner);
		SetAttenuationScalingAllEmitters(10000);
	}


	UFUNCTION(BlueprintPure)
	float GetPullSpeed()
	{
		return FauxPhysicsTranslate.GetVelocity().Size();
	}

	UFUNCTION(BlueprintPure)
	float GetPullProgress()
	{
		float PullAlpha = HazeOwner.RootComponent.GetWorldLocation().X - FauxPhysicsTranslate.GetWorldLocation().X;
		return 1 - (PullAlpha / FauxPhysicsTranslate.MaxX);
	}
}