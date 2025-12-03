class ASanctuaryBossInsideRainProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ProjectileRoot;

	UPROPERTY(DefaultComponent, Attach = ProjectileRoot)
	UStaticMeshComponent ProjectileMeshComp;

	UPROPERTY(DefaultComponent, Attach = ProjectileRoot)
	UNiagaraComponent TrailVFXComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDecalComponent DecalComp;

	UPROPERTY()
	UNiagaraSystem ImpactVFX;

	UPROPERTY()
	float FallSpeed;

	UPROPERTY()
	float ExplosionRadius;

	UPROPERTY()
	FHazeTimeLike DecalAppearTimeLike;
	default DecalAppearTimeLike.UseSmoothCurveZeroToOne();
	default DecalAppearTimeLike.Duration = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DecalAppearTimeLike.BindUpdate(this, n"DecalAppearTimeLikeUpdate");
		DecalAppearTimeLike.Play();

		FVector ProjectileOffset = Math::GetRandomPointInCircle_XY() * 500.0;

		DecalComp.SetRelativeLocation(ProjectileOffset);
		ProjectileRoot.SetRelativeLocation(ProjectileOffset + FVector::UpVector * 10000.0);
	}

	UFUNCTION()
	private void DecalAppearTimeLikeUpdate(float CurrentValue)
	{
		DecalComp.SetWorldScale3D(FVector(Math::Lerp(0.01, 1.0, CurrentValue)));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ProjectileRoot.AddRelativeLocation(FVector::DownVector * DeltaSeconds * FallSpeed);

		if (ProjectileRoot.RelativeLocation.Z <= 0.0)
			Explode();
	}

	private void Explode()
	{
		
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ImpactVFX, ProjectileRoot.WorldLocation);

		for (auto Player : Game::GetPlayers())
		{
			if (Player.ActorLocation.Distance(ProjectileRoot.WorldLocation) < ExplosionRadius)
				Player.KillPlayer();
		}

		DestroyActor();
	}
};