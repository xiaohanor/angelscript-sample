class UDefaultSettingsComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	TArray<UHazeComposableSettings> DefaultSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		if (!ensure(HazeOwner != nullptr, "Default settings component on actor " + Owner.Name + " which is not a HazeActor, will not work!"))
			return;
		for (UHazeComposableSettings Settings : DefaultSettings)
		{
			HazeOwner.ApplyDefaultSettings(Settings);
		}
	}
}
