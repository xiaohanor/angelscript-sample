class AStormChaseFallingPillar : AHazeActor
{
	UPROPERTY()
	FOnMuralKnockedOver OnMuralKnockedOver;

	UPROPERTY()
	FonFallCompleted OnFallCompleted;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MuralRoot;

	UPROPERTY(DefaultComponent, Attach = MuralRoot)
	UStaticMeshComponent MuralMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FallenMuralRoot;
	
	UPROPERTY(DefaultComponent, Attach = FallenMuralRoot)
	UStaticMeshComponent FallenMuralMeshComp;
	default FallenMuralMeshComp.SetHiddenInGame(true);

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere)
	bool bCanBeKnocked;

	bool bHaveHitNextMural;
	bool bHaveCompletedFall;
	bool bHaveBeenKnocked;

	float FallSpeed;

	UPROPERTY(EditAnywhere)
	float FallSpeedTarget = HALF_PI * 1.2;

	AGiantFallingObject PriorPillar;

	UPROPERTY(EditAnywhere, Category = "Audio")
	UHazeAudioEvent PillarFallEvent;

	UPROPERTY(EditAnywhere, Category = "Audio")
	FHazeAudioFireForgetEventParams AudioEventParams;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FallSpeed = Math::FInterpConstantTo(FallSpeed, FallSpeedTarget, DeltaSeconds, FallSpeedTarget / 2);
		MuralRoot.RelativeRotation = Math::QInterpConstantTo(MuralRoot.RelativeRotation.Quaternion(), FallenMuralRoot.RelativeRotation.Quaternion(), DeltaSeconds, FallSpeed).Rotator();

		float Dot = MuralRoot.RelativeRotation.Vector().DotProduct(FallenMuralRoot.RelativeRotation.Vector()); 

		if (!bHaveCompletedFall && Dot > 0.99999)
		{
			bHaveCompletedFall = true;
			Game::Mio.PlayCameraShake(CameraShake, this, 1.0);
			Game::Zoe.PlayCameraShake(CameraShake, this, 1.0);
			SetActorTickEnabled(false);
			OnFallCompleted.Broadcast();
		}
	}

	UFUNCTION()
	void KnockOver()
	{
		if (bHaveCompletedFall)
			return;

		if (bHaveBeenKnocked)
			return;
		
		bHaveBeenKnocked = true;
		FallSpeed = 0.0;

		if (CameraShake != nullptr)
		{
			Game::Mio.PlayCameraShake(CameraShake, this, 1.0);
			Game::Zoe.PlayCameraShake(CameraShake, this, 1.0);
		}

		SetActorTickEnabled(true);

		OnMuralKnockedOver.Broadcast();
		
		if(PillarFallEvent != nullptr)
		{
			AudioComponent::PostFireForget(PillarFallEvent, AudioEventParams);
		}
	}
	
	UFUNCTION()
	void Impact()
	{
		FallSpeed = 0.0;
	}
};