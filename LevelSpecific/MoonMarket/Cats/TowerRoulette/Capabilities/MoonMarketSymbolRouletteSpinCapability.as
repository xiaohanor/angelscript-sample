class UMoonMarketSymbolRouletteSpinCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AMoonMarketSymbolRouletteManager Manager;
	float SpinSpeed = 700.0;
	FRotator OriginalRot1;
	FRotator OriginalRot2;
	float Duration = 1.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = Cast<AMoonMarketSymbolRouletteManager>(Owner);
		OriginalRot1 = Manager.RouletteCube1.ActorRotation;
		OriginalRot2 = Manager.RouletteCube2.ActorRotation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Manager.State != EMoonMarketSymbolRouletteState::RouletteSpin)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Duration)
			return true;

		if (Manager.State == EMoonMarketSymbolRouletteState::Disabled)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Reset Cube Rotations
		Manager.RouletteCube1.ActorRotation = OriginalRot1;
		Manager.RouletteCube2.ActorRotation = OriginalRot2;

		Manager.ChooseTypes();
		Manager.State = EMoonMarketSymbolRouletteState::Countdown;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PrintToScreen("Roulette Spin");
		//Spin Cubes
		Manager.RouletteCube1.AddActorLocalRotation(FRotator(SpinSpeed * DeltaTime, 0, SpinSpeed * DeltaTime));
		Manager.RouletteCube2.AddActorLocalRotation(FRotator(-SpinSpeed * DeltaTime, 0, SpinSpeed * DeltaTime));
	}
};