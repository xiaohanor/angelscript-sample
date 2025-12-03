class UAlienCruiserStopSpinningCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	AAlienCruiser Cruiser;

	float StartRotationSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Cruiser = Cast<AAlienCruiser>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Cruiser.bIsDestroyed)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Cruiser.bIsDestroyed)
			return true;

		if(ActiveDuration >= Cruiser.StopSpinningDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartRotationSpeed = Cruiser.CurrentRotationSpeed;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Cruiser.CurrentRotationSpeed = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = ActiveDuration / Cruiser.SpinUpDuration;
		Cruiser.CurrentRotationSpeed = Math::Lerp(Cruiser.IdleRotationSpeed, 0, Alpha);
		Cruiser.RotateMissileArms(DeltaTime);
	}
}