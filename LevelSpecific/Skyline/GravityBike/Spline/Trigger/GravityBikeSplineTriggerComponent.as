UCLASS(NotBlueprintable, NotPlaceable)
class UGravityBikeSplineTriggerComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	access Internal = private, UGravityBikeSplineTriggerCapability;
	access Trigger = private, AGravityBikeSplineTrigger;

	private AGravityBikeSpline GravityBike;

	access:Internal
	TArray<FGravityBikeSplineTriggerAppliedSetting> AppliedSettings;
	TSet<AGravityBikeSplineTrigger> CurrentTriggers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
	}

	access:Trigger
	void ApplyTrigger(AGravityBikeSplineTrigger Trigger)
	{
		for(auto Settings : Trigger.SettingsToApply)
		{
			ApplySetting(Settings, Trigger);
		}
	}

	access:Internal
	void ApplySetting(FGravityBikeSplineTriggerSetting Settings, AGravityBikeSplineTrigger Trigger)
	{
		FGravityBikeSplineTriggerAppliedSetting AppliedSetting = FGravityBikeSplineTriggerAppliedSetting(Settings, Trigger);
		AppliedSetting.Apply(GravityBike);
		AppliedSettings.Add(AppliedSetting);

		SetComponentTickEnabled(true);
	}

	access:Internal
	void ClearAppliedSetting(int Index)
	{
		AppliedSettings[Index].Clear(GravityBike);
		AppliedSettings.RemoveAt(Index);

		if(AppliedSettings.Num() == 0)
			SetComponentTickEnabled(false);
	}
};