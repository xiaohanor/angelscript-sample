
UCLASS(Abstract)
class UWorld_Sanctuary_Shared_Interactable_LightBird_LightSphere_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	ASanctuaryAntiGravityField AntiGravityField;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		AntiGravityField = Cast<ASanctuaryAntiGravityField>(HazeOwner);
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AntiGravityField.LightBirdResponseComponent.OnIlluminated.AddUFunction(this, n"OnIlluminated");
		AntiGravityField.LightBirdResponseComponent.OnUnilluminated.AddUFunction(this, n"OnUnilluminated");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	private void OnIlluminated()
	{
	}

	UFUNCTION(BlueprintEvent)
	private void OnUnilluminated()
	{
	}
}