class ASoftSplitSplineEnemy : AWorldLinkDoubleActor
{

	UHazeSplineComponent SplineComp;

	UPROPERTY()
	float Speed = 150;

	float CurrentSplineDistance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	//	ActorRotation = FRotator(0,Math::RandRange(0.0,350.0),0);

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	//	AddActorWorldOffset(ActorForwardVector * Speed);
		CurrentSplineDistance += Speed * DeltaSeconds;

		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentSplineDistance);

		SetActorRotation(SplineComp.GetWorldRotationAtSplineDistance(CurrentSplineDistance));

		for(auto Player : Game::Players)
		{
			if (GetDistanceTo(Player) < 100.0)
			{
				Player.KillPlayer();
				DestroyActor();
			}
		}


			if(CurrentSplineDistance >= SplineComp.SplineLength)
			{
				DestroyActor();
			}

	}
};