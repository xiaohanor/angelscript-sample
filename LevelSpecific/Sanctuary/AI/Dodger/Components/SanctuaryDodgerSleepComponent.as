class USanctuaryDodgerSleepComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, Category = "Sleeping")
	bool bSleeping;

	UPROPERTY(EditAnywhere, Category = "Sleeping")
	bool bStandingSleep;

	UPROPERTY()
	bool bWaking;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bSleeping)
			Sleep();

		ULightBirdResponseComponent::Get(Owner).OnAttached.AddUFunction(this, n"OnLightBirdAttached");
		ULightBirdResponseComponent::Get(Owner).OnIlluminated.AddUFunction(this, n"OnLightBirdIlluminated");
		UDarkPortalResponseComponent::Get(Owner).OnGrabbed.AddUFunction(this, n"OnDarkPortalGrabbed");
	}

	UFUNCTION()
	private void OnLightBirdAttached()
	{
		Wake();
	}

	UFUNCTION()
	private void OnDarkPortalGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponenet)
	{
		Wake();
	}

	UFUNCTION()
	private void OnLightBirdIlluminated()
	{
		Wake();
	}

	bool IsSleeping()
	{
		return bSleeping;
	}

	void Sleep()
	{
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		UBasicAISettings::SetAwarenessRange(HazeOwner, 0, this, Priority = EHazeSettingsPriority::Gameplay);

		Timer::SetTimer(this, n"DelayedSleep", 0.1);

		bSleeping = true;
	}

	UFUNCTION()
	private void DelayedSleep()
	{
		if(bWaking)
			return;
		
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		auto DodgerSettings = USanctuaryDodgerSettings::GetSettings(HazeOwner);
		UBasicAISettings::SetAwarenessRange(HazeOwner, DodgerSettings.SleepWakeRange, this, Priority = EHazeSettingsPriority::Gameplay);
	}

	void Wake()
	{
		bWaking = true;
		bSleeping = false;
	}

	void FinishWake()
	{
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.ClearSettingsByInstigator(this);
		bSleeping = false;
	}
}