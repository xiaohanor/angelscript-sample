class ATundraBossSplineRespawnActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPlayerRespawnComponent MioRespawnComp;
	UPlayerRespawnComponent ZoeRespawnComp;
	UHazeSplineComponent SplineComp;

	UFUNCTION()
	void ActivateSplineRespawn(UHazeSplineComponent Spline)
	{
		MioRespawnComp = UPlayerRespawnComponent::Get(Game::Mio);
		ZoeRespawnComp = UPlayerRespawnComponent::Get(Game::Zoe);
		SplineComp = Spline;

		MioRespawnComp.ApplyRespawnOverrideDelegate(this, FOnRespawnOverride(this, n"OnRespawn"), EInstigatePriority::High);
		ZoeRespawnComp.ApplyRespawnOverrideDelegate(this, FOnRespawnOverride(this, n"OnRespawn"), EInstigatePriority::High);
	}

	UFUNCTION()
	void DeactivateSplineRespawn()
	{
		if(MioRespawnComp != nullptr)
			MioRespawnComp.ClearRespawnOverride(this);
		
		if(ZoeRespawnComp != nullptr)
			ZoeRespawnComp.ClearRespawnOverride(this);
	}
	
	UFUNCTION()
	private bool OnRespawn(AHazePlayerCharacter Player, FRespawnLocation& OutLocation)
	{
		float Dist = SplineComp.GetClosestSplineDistanceToWorldLocation(Player.OtherPlayer.ActorLocation);
		OutLocation.RespawnTransform = SplineComp.GetWorldTransformAtSplineDistance(Dist + 500);
		OutLocation.RespawnTransform.Location = FVector(OutLocation.RespawnTransform.Location.X, OutLocation.RespawnTransform.Location.Y, ActorLocation.Z);
		return true;
	}
};