class URemoteHackableCoffeeMachineSpeedCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	URemoteHackableCoffeeMachinePlayerComponent CoffeeComp;

	float StartTime = 0.0;
	float MaxDuration = 4.0;
	float MaxTimeDilation = 2.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CoffeeComp = URemoteHackableCoffeeMachinePlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CoffeeComp.bCoffeeDrunk)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Time::GetRealTimeSince(StartTime) >= MaxDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartTime = Time::RealTimeSeconds;
		CoffeeComp.bCoffeeDrunk = false;

		URemoteHackableCoffeeMachinePlayerEffectEventHandler::Trigger_CoffeeDrunk(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearActorTimeDilation(this);

		URemoteHackableCoffeeMachinePlayerEffectEventHandler::Trigger_CoffeeSubsided(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TimeDilation = Math::Lerp(MaxTimeDilation, 1.0, Time::GetRealTimeSince(StartTime)/MaxDuration);
		Player.SetActorTimeDilation(TimeDilation, this);

		FRemoteHackableCoffeeMachinePlayerEffectEventHandlerParams Params;
		Params.TimeDilation = TimeDilation;
		URemoteHackableCoffeeMachinePlayerEffectEventHandler::Trigger_CoffeeTick(Player, Params);
	}
}