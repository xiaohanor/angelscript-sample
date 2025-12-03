
enum ECameraPointOfInterestSettingsType
{
	Default,
	Clamped
}

// A component use for applying point of interest
// Place this on a camera volume to apply the settings automatically.
// Else, the apply functions and update functions requires manual calls
class UCameraPointOfInterestSettingsComponent : UHazeCameraSettingsComponentBase
{
	UPROPERTY(NotEditable, Category = "Deprecated")
	protected FHazePointOfInterestFocusTargetInfo FocusTarget;

	UPROPERTY(EditAnywhere, Category = "Settings", meta = (EditCondition="Settings == nullptr", EditConditionHides))
	protected ECameraPointOfInterestSettingsType Type = ECameraPointOfInterestSettingsType::Default;

	UPROPERTY(EditAnywhere, Category = "Settings", meta = (EditCondition="Type == ECameraPointOfInterestSettingsType::Default", EditConditionHides))
	protected FApplyPointOfInterestSettings DefaultSettings;

	UPROPERTY(EditAnywhere, Category = "Settings", meta = (EditCondition="Type == ECameraPointOfInterestSettingsType::Clamped", EditConditionHides))
	protected FApplyClampPointOfInterestSettings ClampedSettings;
	
	UPROPERTY(EditAnywhere, Category = "Settings", meta = (EditCondition="Type == ECameraPointOfInterestSettingsType::Clamped", EditConditionHides))
	protected FHazeCameraClampSettings Clamps;


	UFUNCTION(BlueprintOverride)
	void OnApplied(UHazeCameraUserComponent User, FInstigator Instigator)
	{
		auto PlayerUser = Cast<AHazePlayerCharacter>(User.GetOwner());
		if(PlayerUser == nullptr)
			return;

		// We have clamped settings
		if(Type == ECameraPointOfInterestSettingsType::Clamped)
		{
			PlayerUser.ApplyClampedPointOfInterest(Instigator, FocusTarget, ClampedSettings, Clamps, Blend, Priority);
			return;
		}

		PlayerUser.ApplyPointOfInterest(Instigator, FocusTarget, DefaultSettings, Blend, Priority);
	}

	UFUNCTION(BlueprintOverride)
	void OnCleared(UHazeCameraUserComponent User, FInstigator Instigator)
	{
		User.ClearPointOfInterestByInstigator(Instigator);
	}
}