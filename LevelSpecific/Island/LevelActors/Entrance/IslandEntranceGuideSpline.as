class AIslandEntranceGuideSpline : ASplineActor
{
	float LowestPoint;
	float StartDistanceToLowestPoint;

	TPerPlayer<bool> IsOverLowestPoint;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ForcePerDistanceToSpline = 0.45;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ForcePerDistanceTravelled = 0.035;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(true);
		LowestPoint = Spline.BoundsOrigin.Z -Spline.BoundsExtent.Z;

		StartDistanceToLowestPoint = Game::Mio.ActorLocation.Z - LowestPoint;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bool bBothPlayersAreBelow = true;
		for(auto Player : Game::Players)
		{
			bool bIsBelow = Player.ActorLocation.Z < LowestPoint;
			IsOverLowestPoint[Player] = bIsBelow;
			if(!bIsBelow)
			{
				bBothPlayersAreBelow = false;
				auto ClosestSplinePos = Spline.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);

				float DistanceToSplinePos = ClosestSplinePos.WorldLocation.Distance(Player.ActorLocation);
				if(DistanceToSplinePos < ClosestSplinePos.WorldScale3D.Y)
					continue;

				FVector ImpulseDir = ((ClosestSplinePos.WorldLocation - Player.ActorLocation).ConstrainToPlane(Player.MovementWorldUp)).GetSafeNormal();

				float DistanceFromLowestPoint = Player.ActorLocation.Z - LowestPoint;
				float DistanceTravelled = StartDistanceToLowestPoint - DistanceFromLowestPoint;
				float Force = (DistanceToSplinePos * ForcePerDistanceToSpline) + (DistanceTravelled * ForcePerDistanceTravelled); 
				// Player.AddMovementImpulse(ImpulseDir * Force * DeltaSeconds);
			}
		}
		if(bBothPlayersAreBelow)
			AddActorDisable(this);


	}
};