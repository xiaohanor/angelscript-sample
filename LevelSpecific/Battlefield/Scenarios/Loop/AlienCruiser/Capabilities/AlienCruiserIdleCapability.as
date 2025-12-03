class UAlienCruiserIdleCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	AAlienCruiser Cruiser;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Cruiser = Cast<AAlienCruiser>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Cruiser.bShouldShoot)
			return false;

		if(Cruiser.bIsDestroyed)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Cruiser.bShouldShoot)
			return true;

		if(Cruiser.bIsDestroyed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Cruiser.CurrentRotationSpeed = Cruiser.IdleRotationSpeed; 
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Cruiser.RotateMissileArms(DeltaTime);
	}
}