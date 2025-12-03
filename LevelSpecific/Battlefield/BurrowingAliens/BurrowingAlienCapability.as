class UBurrowingAlienCapability : UHazeCapability
{
	default CapabilityTags.Add(n"BurrowingAlienCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ABurrowingAlien Burrower;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Burrower = Cast<ABurrowingAlien>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Burrower.CanActivate())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if ((Burrower.AlienBurrowerRoot.WorldLocation - Burrower.EndLoc).Size() < 1.0)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Burrower.ActivateAlienBurrower();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Burrower.AlienBurrowerRoot.WorldLocation = Math::VInterpTo(Burrower.AlienBurrowerRoot.WorldLocation, Burrower.EndLoc, DeltaTime, 1.25);
	}
}
