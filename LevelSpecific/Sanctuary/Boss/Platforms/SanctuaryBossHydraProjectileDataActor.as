class ASanctuaryBossHydraProjectileDataActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USpotLightComponent TelegraphSpotLight;
	default TelegraphSpotLight.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent ProjectileMeshComp;
	default ProjectileMeshComp.bHiddenInGame = true;

	UPROPERTY()
	UNiagaraSystem SplashVFXSystem;

	UPROPERTY(EditInstanceOnly)
	float TelegraphDuration = 6.0;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossLoopingPlatform Platform;

	UPROPERTY()
	FHazeTimeLike TelegraphTimeLike;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TelegraphTimeLike.BindUpdate(this, n"TelegraphTimelikeUpdate");
		TelegraphTimeLike.BindFinished(this, n"TelegraphTimelikeFinished");
		TelegraphTimeLike.Duration = TelegraphDuration;
	}

	UFUNCTION()
	void TelegraphTimelikeUpdate(float Alpha)
	{
		TelegraphSpotLight.SetOuterConeAngle(Math::Lerp(0.0, 20.0, Alpha));

		FVector ProjectileLocation = (FVector::UpVector * 20000) - (FVector::UpVector * TelegraphTimeLike.Position * 20000.0);
		ProjectileMeshComp.SetRelativeLocation(ProjectileLocation);
	}

	UFUNCTION()
	void TelegraphTimelikeFinished()
	{
		TelegraphSpotLight.SetHiddenInGame(true);
		ProjectileMeshComp.SetHiddenInGame(true);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(SplashVFXSystem, ActorLocation);

		if (IsValid(Platform))
			Platform.ProjectileImpactTimelike.PlayFromStart();
	}

	UFUNCTION(BlueprintCallable)
	void SendAttackData()
	{
		if (!HasControl())
			return;

		CrumbSendAttackData();
	}

	UFUNCTION(CrumbFunction)
	void CrumbSendAttackData()
	{
		TelegraphTimeLike.PlayFromStart();
		TelegraphSpotLight.SetHiddenInGame(false);
		ProjectileMeshComp.SetHiddenInGame(false);
	}
};