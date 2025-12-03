class UIslandSupervisorActiveCapability : UIslandSupervisorChildCapability
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Supervisor.IsActive())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Supervisor.IsActive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Supervisor.OnActivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FRotator Rotation = Math::RInterpShortestPathTo(Supervisor.EyeBall.WorldRotation, TargetRotation, DeltaTime, 7.0);
		Supervisor.SetClampedEyeRotation(Rotation);
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

	FRotator GetTargetRotation() property
	{
		float ClosestSqrDist;
		AHazePlayerCharacter ClosestPlayer = GetClosestPlayer(ClosestSqrDist);
		if(ClosestSqrDist > Math::Square(Supervisor.PlayerDetectionRange))
			return Supervisor.ActorRotation;

		return FRotator::MakeFromX(ClosestPlayer.Mesh.GetSocketLocation(n"Head") - Supervisor.EyeBall.WorldLocation);
	}
}