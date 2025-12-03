class UPigMazePowerupPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UPigMazePowerupPlayerComponent PowerupComp;
	UPlayerPigComponent PigComp;

	UNiagaraComponent PoweredUpEffectComp;

	FHazeTimeLike ScaleTimeLike;
	default ScaleTimeLike.Duration = 0.2;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PowerupComp = UPigMazePowerupPlayerComponent::Get(Player);

		ScaleTimeLike.BindUpdate(this, n"UpdateScale");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PowerupComp.bPowerupActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!PowerupComp.bPowerupActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PigComp = UPlayerPigComponent::Get(Player);

		PoweredUpEffectComp = Niagara::SpawnLoopingNiagaraSystemAttached(PowerupComp.PoweredUpSystem, Player.RootComponent);
		ScaleTimeLike.Play();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PoweredUpEffectComp.Deactivate();
		ScaleTimeLike.Reverse();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}

	UFUNCTION()
	void UpdateScale(float CurValue)
	{
		float Scale = Math::Lerp(1.0, 2.0, CurValue);
		Player.Mesh.SetRelativeScale3D(FVector(Scale));
	}
}