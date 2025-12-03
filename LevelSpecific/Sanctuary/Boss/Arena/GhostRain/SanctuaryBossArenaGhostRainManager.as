class ASanctuaryBossArenaGhostRainManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RainHazeRoot;

	UPROPERTY()
	TSubclassOf<ASanctuaryBossArenaGhostRainProjectile> ProjectileClass;

	UPROPERTY(EditAnywhere, Category = Settings)
	float HeightOffset = 2000.0;

	UPROPERTY(EditAnywhere, Category = Settings)
	float MinIntensity = 0.4;

	UPROPERTY(EditAnywhere, Category = Settings)
	float MaxIntensity = 0.04;

	UPROPERTY(EditAnywhere, Category = Settings)
	float MaxHorizontalOffset = 1000.0;

	UPROPERTY(EditAnywhere, Category = Settings)
	float ProjectileSpacing = 200.0;

	UPROPERTY(EditAnywhere, Category = Settings)
	int HorizontalProjectiles = 50;

	UPROPERTY(EditInstanceOnly)
	AActor SplineActor;
	UHazeSplineComponent SplineComp;
	float PlayerSplineDistance;

	FHazeTimeLike RainHazeAppearTimeLike;
	default RainHazeAppearTimeLike.UseSmoothCurveZeroToOne();
	default RainHazeAppearTimeLike.Duration = 3.0;

	UPROPERTY()
	FHazeTimeLike ProjectileIntensityTimeLike;
	default ProjectileIntensityTimeLike.UseSmoothCurveZeroToOne();
	default ProjectileIntensityTimeLike.Duration = 6.0; 

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = UHazeSplineComponent::Get(SplineActor);

		if (SplineComp == nullptr)
			PrintToScreen("FOUND NO SPLINE FOR GHOST RAIN MANAGER", 5.0, FLinearColor::Red);

		RainHazeAppearTimeLike.BindUpdate(this, n"RainHazeAppearTimeLikeUpdate");
		RainHazeAppearTimeLike.BindFinished(this, n"RainHazeAppearTimeLikeFinished");

		RainHazeRoot.SetHiddenInGame(true, true);
	}

	UFUNCTION()
	private void RainHazeAppearTimeLikeUpdate(float CurrentValue)
	{
		BP_UpdateRainHaze(CurrentValue);
	}

	UFUNCTION()
	private void RainHazeAppearTimeLikeFinished()
	{
		if (RainHazeAppearTimeLike.IsReversed())
			RainHazeRoot.SetHiddenInGame(true, true);
	}

	UFUNCTION()
	void StartGhostRain()
	{
		RainHazeAppearTimeLike.Play();

		RainHazeRoot.SetHiddenInGame(false, true);

	    //Timer::SetTimer(this, n"StartSpawningProjectiles", 4.0);
		SpawnProjectile();

		Timer::SetTimer(this, n"ReverseHaze", 6.0);
	}

	UFUNCTION()
	private void ReverseHaze()
	{
		RainHazeAppearTimeLike.Reverse();
	}
	
	UFUNCTION(BlueprintEvent)
	private void BP_UpdateRainHaze(float CurrentValue) {}

	UFUNCTION()
	private void SpawnProjectile()
	{
		for (auto Player : Game::GetPlayers())
		{
			USanctuaryCompanionAviationPlayerComponent AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
			if (AviationComp.GetIsAviationActive())
				continue;
			for (int i=0; i<=HorizontalProjectiles; i++)
			{
				SpawnProjectileInternal(GetSpawnLocation(GetPlayerSplineDistance(Player) + (ProjectileSpacing * (i + 0.5))), AviationComp);
				SpawnProjectileInternal(GetSpawnLocation(GetPlayerSplineDistance(Player) + (ProjectileSpacing * -(i + 0.5))), AviationComp);
			}
		}
	}

	private void SpawnProjectileInternal(FVector Location, USanctuaryCompanionAviationPlayerComponent AviationComp)
	{
		FVector ToProjectile = Location - ActorLocation;
		ToProjectile.Z = 0.0;
		FRotator Rotation = FRotator::MakeFromXZ(ToProjectile.GetSafeNormal(), FVector::UpVector);
		ASanctuaryBossArenaGhostRainProjectile Projectile = SpawnActor(ProjectileClass, Location, Rotation);
		Projectile.SetAviationComp(AviationComp);
	}

	private float GetPlayerSplineDistance(AHazePlayerCharacter Player)
	{
		float SplineDistance = SplineComp.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		return SplineDistance;
	}

	private FVector GetSpawnLocation(float InSplineDistance)
	{
		float SplineDistance = InSplineDistance;

		if (SplineDistance > SplineComp.SplineLength)
			SplineDistance -= SplineComp.SplineLength;

		if (SplineDistance < 0.0)
			SplineDistance += SplineComp.SplineLength;

		FVector ReturnValue = SplineComp.GetWorldLocationAtSplineDistance(SplineDistance) + FVector::UpVector * HeightOffset;
		return ReturnValue;
	}
};