class ASanctuaryBossInsideGhostProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	float Speed = 2000.0;

	UPROPERTY()
	float Radius = 300.0;

	UPROPERTY()
	float Damage = 0.5;

	UPROPERTY()
	float TelegraphDuration = 1.0;



	UHazeSplineComponent SplineComp;
	bool bReversed = false;
	float SplineProgress;

	bool bTelegraphing = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bReversed)
			SplineProgress = SplineComp.SplineLength;
		else
			SplineProgress = 0.0;

		FVector TargetLocation = SplineComp.GetWorldLocationAtSplineFraction(bReversed ? 0.0 : 1.0);
		FRotator TargetRotation = SplineComp.GetWorldRotationAtSplineFraction(bReversed ? 0.0 : 1.0).Rotator();


		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bReversed)
		{
			SplineProgress -= Speed * DeltaSeconds;

			if (SplineProgress <= 0.0)
			{
				Explode();
			}

		
		}
		else
		{
			SplineProgress += Speed * DeltaSeconds;

			if (SplineProgress >= SplineComp.SplineLength)
			{
				Explode();
			}

	
		}

		FVector Location = SplineComp.GetWorldLocationAtSplineDistance(SplineProgress);
		FRotator Rotation = SplineComp.GetWorldRotationAtSplineDistance(SplineProgress).Rotator();
		SetActorLocationAndRotation(Location, Rotation);
	}

	private void Explode()
	{
		BP_Explode();

		for (auto Player : Game::GetPlayers())
		{
			if (ActorLocation.Distance(Player.ActorLocation) < Radius)
				Player.DamagePlayerHealth(Damage);
		}

		DestroyActor();
	}



	UFUNCTION(BlueprintEvent)
	private void BP_Explode()
	{}
};