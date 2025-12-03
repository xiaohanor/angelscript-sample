class AMeltdownBossPhaseOneBounceAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, NotEditable)
	UMeltdownBossCubeGridDisplacementComponent DisplacementComp;

	UPROPERTY(EditAnywhere)
	float Duration = 5.0;
	UPROPERTY(EditAnywhere)
	AActor ConstraintVolume;

	UPROPERTY(EditAnywhere)
	TArray<AActor> Obstacles;

	UPROPERTY(EditAnywhere)
	float Speed = 1000.0;
	UPROPERTY(EditAnywhere)
	float Radius = 200.0;
	UPROPERTY(EditAnywhere)
	FVector Displacement = FVector(0, 0, 200);

	FTransform OriginalLocation;
	bool bTriggered = false;
	bool bAutoDestroy = false;
	float Timer = 0.0;

	float MinX;
	float MaxX;
	float MinY;
	float MaxY;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalLocation = ActorTransform;
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		UpdateDisplacement();
	}

	void UpdateDisplacement()
	{
		DisplacementComp.Type = EMeltdownBossCubeGridDisplacementType::Shape;

		DisplacementComp.Shape = FHazeShapeSettings::MakeSphere(Radius * 0.5);
		DisplacementComp.LerpDistance = Radius * 0.5;
		DisplacementComp.Displacement = Displacement;
		DisplacementComp.bInfiniteHeight = true;
	}

	UFUNCTION(DevFunction)
	void TriggerAttack()
	{
		bTriggered = true;
		Timer = 0.0;

		ActorTransform = OriginalLocation;
		DisplacementComp.ActivateDisplacement();
		RemoveActorDisable(this);

		if (ConstraintVolume != nullptr)
		{
			FVector Origin;
			FVector Extent;
			ConstraintVolume.GetActorBounds(true, Origin, Extent);

			MinX = Origin.X - Extent.X;
			MaxX = Origin.X + Extent.X;

			MinY = Origin.Y - Extent.Y;
			MaxY = Origin.Y + Extent.Y;
		}
	}

	void CheckKillPlayers()
	{
		for (auto Player : Game::Players)
		{
			if (Player.IsPlayerDead())
				continue;

			FVector PlayerLocation = Player.ActorLocation;
			FVector DisplaceLocation = DisplacementComp.WorldLocation;

			float Distance = PlayerLocation.Distance(DisplaceLocation);
			if (Distance < Radius)
			{
				bool bPlayerIsAboveCubeGrid = false;
				
				TListedActors<AMeltdownBossCubeGrid> CubeGrids;
				for (AMeltdownBossCubeGrid Grid : CubeGrids)
				{
					if (Grid.IsLocationWithinGrid2D(Player.ActorLocation, 10.0))
						bPlayerIsAboveCubeGrid = true;
				}

				if (bPlayerIsAboveCubeGrid)
					Player.KillPlayer();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bTriggered)
			return;

		Timer += DeltaSeconds;
		FVector NewLocation = ActorLocation + (ActorForwardVector * (DeltaSeconds * Speed));

		// Check when we've left the constraint volume
		if (NewLocation.X < MinX)
		{
			NewLocation.X = MinX;
			ActorRotation = FRotator::MakeFromX(Math::GetReflectionVector(
				ActorForwardVector, FVector(1, 0, 0)
			));
		}
		else if (NewLocation.X > MaxX)
		{
			NewLocation.X = MaxX;
			ActorRotation = FRotator::MakeFromX(Math::GetReflectionVector(
				ActorForwardVector, FVector(-1, 0, 0)
			));
		}
		else if (NewLocation.Y < MinY)
		{
			NewLocation.Y = MinY;
			ActorRotation = FRotator::MakeFromX(Math::GetReflectionVector(
				ActorForwardVector, FVector(0, 1, 0)
			));
		}
		else if (NewLocation.Y > MaxY)
		{
			NewLocation.Y = MaxY;
			ActorRotation = FRotator::MakeFromX(Math::GetReflectionVector(
				ActorForwardVector, FVector(0, -1, 0)
			));
		}

		// Check if we hit any obstacles
		for (auto Obstacle : Obstacles)
		{
			if (Obstacle == nullptr)
				continue;

			FHitResult Hit;
			if (Obstacle.LineTraceActor(ActorLocation, NewLocation, ETraceTypeQuery::WeaponTraceEnemy, false, Hit))
			{
				if (!Hit.bStartPenetrating)
				{
					FVector Direction = (NewLocation - ActorLocation).GetSafeNormal();
					NewLocation = Hit.Location;
					ActorRotation = FRotator::MakeFromX(Math::GetReflectionVector(
						Direction, Hit.Normal
					));
				}
			}
		}

		ActorLocation = NewLocation;

		UpdateDisplacement();
		CheckKillPlayers();

		if (Timer >= Duration)
		{
			AddActorDisable(this);
			if (bAutoDestroy)
				DestroyActor();
		}
	}
};

UFUNCTION(Category = "Meltdown")
void SpawnMeltdownBossPhaseOneBounceAttack(AActor BoundsVolume, FVector Location, FVector Direction, float Radius = 200.0, float Speed = 2000.0, float Duration = 10.0)
{
	auto Attack = AMeltdownBossPhaseOneBounceAttack::Spawn(Location, FRotator::MakeFromZX(FVector::UpVector, Direction));
	Attack.ConstraintVolume = BoundsVolume;
	Attack.Radius = Radius;
	Attack.Speed = Speed;
	Attack.Duration = Duration;
	Attack.bAutoDestroy = true;
	Attack.TriggerAttack();
}