class UAlienCruiserSpinUpCapability : UHazeChildCapability
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
		if(!Cruiser.bShouldShoot)
			return false;

		if(Cruiser.bIsDestroyed)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Cruiser.bShouldShoot)
			return true;

		if(Cruiser.bIsDestroyed)
			return true;

		if(ActiveDuration >= Cruiser.SpinUpDuration)
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
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = ActiveDuration / Cruiser.SpinUpDuration;
		Cruiser.CurrentRotationSpeed = Math::Lerp(StartRotationSpeed, Cruiser.ShootingRotationSpeed, Alpha);
		Cruiser.RotateMissileArms(DeltaTime);
	}
}