
UCLASS(Abstract)
class UVO_DES_Skyline_Highway_CargoScanner_HowToProceed_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY()
	UGravityWhipResponseComponent WhipResponseComp;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		WhipResponseComp = UGravityWhipResponseComponent::Get(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WhipResponseComp.OnGrabbed.AddUFunction(this, n"OnWhipGrabbed");
		WhipResponseComp.OnReleased.AddUFunction(this, n"OnWhipReleased");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WhipResponseComp.OnGrabbed.UnbindObject(this);
		WhipResponseComp.OnReleased.UnbindObject(this);
	}

	UFUNCTION(BlueprintEvent)
	void OnWhipGrabbed (UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents) {}

	UFUNCTION(BlueprintEvent)
	void OnWhipReleased (UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse) {}

}

