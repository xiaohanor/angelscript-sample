class AMeltdownBossPhaseThreePiranhas : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent WorldMesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PortalMesh;

	UPROPERTY(DefaultComponent, Attach = PortalMesh)
	UDecalComponent Telegraph;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent Piranhas;

	FHazeTimeLike WorldAnim;
	default WorldAnim.Duration = 1.0;
	default WorldAnim.UseLinearCurveZeroToOne();

	FHazeTimeLike PortalAnim;
	default PortalAnim.Duration = 1.0;
	default PortalAnim.UseSmoothCurveZeroToOne();

	FVector StartLocation;
	FVector EndLocation;

	FVector StartScale;
	UPROPERTY()
	FVector EndScale;

	FVector PiranhaStartScale;
	FVector PiranhaEndScale;

	UPROPERTY()
	bool bCanDamage;

	AHazePlayerCharacter PlayerTarget;
	float TargetPredictionTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = WorldMesh.RelativeLocation;
		EndLocation = PortalMesh.RelativeLocation;

		StartScale = PortalMesh.RelativeScale3D;

		PiranhaStartScale = FVector(0.1,0.1,0.1);
		PiranhaEndScale = FVector(1.0,1.0,1.0);

		WorldAnim.BindFinished(this, n"DropWorldDone");
		WorldAnim.BindUpdate(this, n"DropWorldUpdate");

		PortalAnim.BindFinished(this, n"OpenWorldDone");
		PortalAnim.BindUpdate(this, n"OpenWorldUpdate");

	}

	UFUNCTION(BlueprintCallable)
	void StartAttack()
	{
		if (PlayerTarget != nullptr)
		{
			FVector NewLocation = ActorLocation;
			NewLocation.X = PlayerTarget.ActorLocation.X;
			NewLocation.Y = PlayerTarget.ActorLocation.Y;

			NewLocation += (PlayerTarget.ActorVelocity * TargetPredictionTime).ConstrainToPlane(FVector::UpVector);
			ActorLocation = NewLocation;
		}
	
		WorldAnim.Play();

		WorldMesh.SetHiddenInGame(false);
		Telegraph.SetHiddenInGame(false);
	}

	UFUNCTION()
	private void OpenWorldUpdate(float CurrentValue)
	{
		PortalMesh.SetRelativeScale3D(Math::Lerp(StartScale,EndScale,CurrentValue));
		Piranhas.SetRelativeScale3D(Math::Lerp(PiranhaStartScale,PiranhaEndScale,CurrentValue));
	}

	UFUNCTION()
	private void OpenWorldDone()
	{
		if(PortalAnim.IsReversed())
		{
		AddActorDisable(this);
		return;
		}

		PortalAnim.Reverse();

	}

	UFUNCTION()
	private void DropWorldUpdate(float CurrentValue)
	{
		WorldMesh.SetRelativeLocation(Math::Lerp(StartLocation,EndLocation, CurrentValue));
	}

	UFUNCTION()
	private void DropWorldDone()
	{
		PortalAnim.Play();
		PortalMesh.SetHiddenInGame(false);
		WorldMesh.SetHiddenInGame(true);
		Telegraph.SetHiddenInGame(true);
		Piranhas.Activate(false);
		bCanDamage = true;
		PlaySplash();
	}

	UFUNCTION(BlueprintEvent)
	void PlaySplash()
	{

	}
};