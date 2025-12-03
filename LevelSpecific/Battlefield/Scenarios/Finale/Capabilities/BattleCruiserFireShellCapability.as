class UBattleCruiserFireShellCapability : UHazeCapability
{
	default CapabilityTags.Add(n"BattleCruiserFireShellCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ABattleCruiserCannon Cannon;

	float FireTime;
	float WaitDuration = 2.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Cannon = Cast<ABattleCruiserCannon>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Cannon.bFiringShells)
			return false;

		if (Time::GameTimeSeconds < FireTime)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FireTime = Time::GameTimeSeconds + WaitDuration;
		
		for (AHazePlayerCharacter Player : Game::Players)
			Player.PlayWorldCameraShake(Cannon.FireShellCameraShake, this, Cannon.ActorLocation, 45000.0, 90000.0);
		
		Cannon.ShootCannon();
	}
}