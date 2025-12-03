class UDesertTiltPoleClimbComponent : UActorComponent
{

	APoleClimbActor PoleClimb;
	TPerPlayer<bool> IsPlayerClimbing;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PoleClimb = Cast<APoleClimbActor>(Owner);

		PoleClimb.OnStartPoleClimb.AddUFunction(this, n"OnStartPoleClimb");
		PoleClimb.OnStopPoleClimb.AddUFunction(this, n"OnStopPoleClimb");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(auto Player : Game::Players)
		{
			if(!IsPlayerClimbing[Player])
				continue;

			FVector RelativeLocation = PoleClimb.ActorTransform.InverseTransformPositionNoScale(Player.ActorLocation);

			float DistanceFromBottom = RelativeLocation.Z;
			FVector HorizontalDirection = RelativeLocation.GetSafeNormal2D();
			
		}
	}

	UFUNCTION()
	private void OnStartPoleClimb(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		IsPlayerClimbing[Player] = true;
	}

	UFUNCTION()
	private void OnStopPoleClimb(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		IsPlayerClimbing[Player] = false;
	}
};