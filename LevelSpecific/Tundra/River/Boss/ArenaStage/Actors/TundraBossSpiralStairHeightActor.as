class ATundraBossSpiralStairHeightActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(EditInstanceOnly)
	ASplineActor Spline;

	TPerPlayer<float> Height;
	float Offset = 500;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(auto Player : Game::Players)
		{
			Height[Player] = Spline.Spline.GetClosestSplineWorldLocationToWorldLocation(Player.ActorLocation).Z;
		}

		FVector NewLoc = FVector(ActorLocation.X, ActorLocation.Y, ((Height[Game::Mio] + Height[Game::Zoe]) * 0.5) + Offset);
		SetActorLocation(NewLoc);
	}
};