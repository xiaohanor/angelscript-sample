class UGoatRainbowRoadCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UGoatRainbowRoadPlayerComponent RainbowRoadComp;

	UNiagaraComponent TrailComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RainbowRoadComp = UGoatRainbowRoadPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsActioning(ActionNames::SecondaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::SecondaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplySettings(RainbowRoadComp.GravitySettings, this);

		TrailComp = Niagara::SpawnLoopingNiagaraSystemAttached(RainbowRoadComp.TrailSystem, Player.RootComponent);
		TrailComp.SetRelativeLocation(FVector(200.0, 0.0, 0.0));

		Player.SetActorHorizontalAndVerticalVelocity(Player.ActorHorizontalVelocity, FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsByInstigator(this);

		TrailComp.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}
}