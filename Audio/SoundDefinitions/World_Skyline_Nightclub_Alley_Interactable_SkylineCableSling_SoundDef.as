
UCLASS(Abstract)
class UWorld_Skyline_Nightclub_Alley_Interactable_SkylineCableSling_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	ASkylineCableSling CableSling;	

	UPROPERTY(EditInstanceOnly)
	float MaxTensionRange = 180.0;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		CableSling = Cast<ASkylineCableSling>(HazeOwner);
		CableSling.GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleWhipGrab");
		CableSling.GravityWhipResponseComponent.OnReleased.AddUFunction(this, n"HandleWhipReleased");
	}

	UFUNCTION()
	void HandleWhipGrab(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		OnWhipGrabbed();
	}
	
	UFUNCTION(BlueprintEvent)
	void OnWhipGrabbed() {}
	
	UFUNCTION()
	void HandleWhipReleased(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		float Intensity = GetCableSlingTension();
		OnWhipReleased(Intensity, CableSling.PerchingPlayers.Num() > 0);		
	}

	UFUNCTION(BlueprintEvent)
	void OnWhipReleased(float SpringStrength, bool bPlayerWasPerching) {}
	
	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Cable Sling Tension"))
	float GetCableSlingTension()
	{
		return Math::Min(1, Math::Abs(CableSling.FauxPhysicsTranslateComponent.RelativeLocation.Z) / MaxTensionRange);
	}
}