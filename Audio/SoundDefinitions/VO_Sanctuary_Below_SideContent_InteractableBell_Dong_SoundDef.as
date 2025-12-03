
UCLASS(Abstract)
class UVO_Sanctuary_Below_SideContent_InteractableBell_Dong_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	ASanctuaryInteractableBell Bell;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Bell = Cast<ASanctuaryInteractableBell>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Bell.DarkPortalResponseComponent.OnReleased.AddUFunction(this, n"HandleReleased");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Bell.DarkPortalResponseComponent.OnReleased.Unbind(this, n"HandleReleased");
	}

	UFUNCTION()
	private void HandleReleased(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		OnInteraction();
	}

	UFUNCTION(BlueprintEvent)
	void OnInteraction() {}
}