class ASanctuaryBossSkydiveGhostProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	USphereComponent SphereCol;

	UPROPERTY()
	float Speed = 2000.0;

	UPROPERTY()
	float Radius = 300.0;

	UPROPERTY()
	float Damage = 0.33;

	UPROPERTY()
	float TelegraphDuration = 1.0;

	UPROPERTY(DefaultComponent)
	UHazeDecalComponent DecalComp;

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

		DecalComp.SetWorldLocationAndRotation(TargetLocation, TargetRotation);
		DecalComp.DetachFromComponent(EDetachmentRule::KeepWorld);

		SphereCol.OnComponentBeginOverlap.AddUFunction(this, n"HandleOverlap");

	
	}



	UFUNCTION()
	private void HandleOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                           UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                           const FHitResult&in SweepResult)
	{
			for (auto Player : Game::GetPlayers())
		{
			if (Player == OtherActor)
				Player.DamagePlayerHealth(Damage);
		}
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

			if (!bTelegraphing && SplineProgress <= Speed)
			{
				ShowTelegraphDecal();
			}
		}
		else
		{
			SplineProgress += Speed * DeltaSeconds;

			if (SplineProgress >= SplineComp.SplineLength)
			{
				Explode();
			}

			if (!bTelegraphing && SplineProgress >= SplineComp.SplineLength - Speed)
			{
				ShowTelegraphDecal();
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

	private void ShowTelegraphDecal()
	{
		bTelegraphing = true;
		DecalComp.SetHiddenInGame(false);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Explode()
	{}
};