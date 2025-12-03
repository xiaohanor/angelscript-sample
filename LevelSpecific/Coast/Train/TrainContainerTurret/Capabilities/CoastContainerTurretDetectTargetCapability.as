class UCoastContainerTurretDetectTargetCapability : UHazeCapability
{
	UCoastContainerTurretDoorComponent TurretDoorComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TurretDoorComp = UCoastContainerTurretDoorComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(TurretDoorComp.DoOpen)
			return false;
		if(TurretDoorComp.IsOpen)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(TurretDoorComp.DoOpen)
			return true;
		if(TurretDoorComp.IsOpen)
			return false;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(AHazePlayerCharacter Player: Game::Players)
		{
			if(Player.ActorLocation.IsWithinDist(Owner.ActorLocation, 2000))
				TurretDoorComp.Open();
		}
	}
}