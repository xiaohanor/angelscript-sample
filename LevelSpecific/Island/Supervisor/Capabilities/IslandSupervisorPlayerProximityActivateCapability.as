class UIslandSupervisorPlayerProximityActivateCapability : UIslandSupervisorChildCapability
{
	AHazePlayerCharacter ClosestPlayer;
	float ClosestSqrDist;

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		ClosestPlayer = GetClosestPlayer(ClosestSqrDist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!IsClosestPlayerInRange())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!IsClosestPlayerInRange())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Supervisor.Activate(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Supervisor.Deactivate(this);
	}

	bool IsClosestPlayerInRange() const
	{
		return ClosestSqrDist < Math::Square(Supervisor.PlayerDetectionRange);
	}

	AHazePlayerCharacter GetClosestPlayer(float&out OutSqrDist) const
	{
		AHazePlayerCharacter TempClosestPlayer;
		OutSqrDist = MAX_flt;
		for(AHazePlayerCharacter Player : Game::Players)
		{
			float SqrDist = Player.ActorLocation.DistSquared(Supervisor.EyeBall.WorldLocation);
			if(SqrDist < OutSqrDist)
			{
				OutSqrDist = SqrDist;
				TempClosestPlayer = Player;
			}
		}

		return TempClosestPlayer;
	}
}