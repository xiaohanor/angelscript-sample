class ASanctuaryWellGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LightRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightDoorPivotComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftDoorPivotComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UStaticMeshComponent OrbMeshComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	USceneComponent DarkPortalTargetComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	USceneComponent LightBirdTargetComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComponent;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComponent;

	UPROPERTY(DefaultComponent)
	USanctuaryInterfaceComponent InterfaceComp;

	UPROPERTY()
	UNiagaraSystem VFXSystem;

	UPROPERTY()
	FHazeTimeLike RotateSpeedTimeLike;
	default RotateSpeedTimeLike.UseSmoothCurveZeroToOne();
	default RotateSpeedTimeLike.Duration = 7.0;

	UPROPERTY()
	FHazeTimeLike UnlockGateTimeLike;
	default OpenGateTimeLike.UseSmoothCurveZeroToOne();
	default OpenGateTimeLike.Duration = 2.0;

	UPROPERTY()
	FHazeTimeLike OpenGateTimeLike;
	default OpenGateTimeLike.UseSmoothCurveZeroToOne();
	default OpenGateTimeLike.Duration = 3.0;

	UPROPERTY()
	FHazeTimeLike LightTimeLike;
	default LightTimeLike.UseSmoothCurveZeroToOne();
	default LightTimeLike.Duration = 3.0;

	UPROPERTY(EditInstanceOnly)
	FDarkPortalInvestigationDestination DarkPortalInvestigationDestination;

	UPROPERTY(EditInstanceOnly)
	FLightBirdInvestigationDestination LightBirdInvestigationDestination;

	UPROPERTY(EditInstanceOnly)
	ADoubleInteractionActor DoubleInteractionActor;

	UPROPERTY(EditAnywhere)
	float MaxRotateSpeed = 1000.0;
	float RotateSpeed = 0.0;

	UPROPERTY(EditAnywhere)
	float CompanionArriveDuration = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RotateSpeedTimeLike.BindUpdate(this, n"SpinTimeLikeUpdate");
		RotateSpeedTimeLike.BindFinished(this, n"SpinTimeLikeFinished");
		UnlockGateTimeLike.BindUpdate(this, n"UnlockGateTimeLikeUpdate");
		UnlockGateTimeLike.BindFinished(this, n"UnlockGateTimeLikeFinished");
		OpenGateTimeLike.BindUpdate(this, n"OpenGateTimeLikeUpdate");

		LightTimeLike.BindUpdate(this, n"LightTimeLikeUpdate");

		DarkPortalInvestigationDestination.TargetComp = DarkPortalTargetComp;
		LightBirdInvestigationDestination.TargetComp = LightBirdTargetComp;

		LightBirdResponseComponent.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
		LightBirdResponseComponent.OnUnilluminated.AddUFunction(this, n"HandleUnilluminated");
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		LightTimeLike.Play();
	}

	UFUNCTION()
	private void HandleUnilluminated()
	{
		LightTimeLike.Reverse();
	}

	UFUNCTION()
	private void LightTimeLikeUpdate(float CurrentValue)
	{
		LightRoot.SetRelativeScale3D(FVector(CurrentValue));
	}

	UFUNCTION()
	void ActivateCompanionInteraction()
	{
		DarkPortalCompanion::DarkPortalInvestigate(DarkPortalInvestigationDestination, this);
		LightBirdCompanion::LightBirdInvestigate(LightBirdInvestigationDestination, this);

		Timer::SetTimer(this, n"StartRotating", CompanionArriveDuration);
		Timer::SetTimer(this, n"ExplodeOrb", CompanionArriveDuration + RotateSpeedTimeLike.Duration * 0.8);
	}


	UFUNCTION()
	void StartRotating()
	{
		RotateSpeedTimeLike.PlayFromStart();
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	private void SpinTimeLikeUpdate(float CurrentValue)
	{
		RotateSpeed = CurrentValue * MaxRotateSpeed;
	}

	UFUNCTION()
	private void SpinTimeLikeFinished()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	void ExplodeOrb()
	{
		OpenGateTimeLike.Play();
		OrbMeshComp.SetHiddenInGame(true, true);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(VFXSystem, OrbMeshComp.WorldLocation);
		DarkPortalCompanion::DarkPortalStopInvestigating(this);
		LightBirdCompanion::LightBirdStopInvestigating(this);
	}


	UFUNCTION()
	private void UnlockGateTimeLikeUpdate(float CurrentValue)
	{
		RightDoorPivotComp.SetRelativeRotation(FRotator(0.0, Math::Lerp(0.0, 10.0, CurrentValue), 0.0));
		LeftDoorPivotComp.SetRelativeRotation(FRotator(0.0, Math::Lerp(0.0, -10.0, CurrentValue), 0.0));
	}

	UFUNCTION()
	private void UnlockGateTimeLikeFinished()
	{
		DoubleInteractionActor.EnableDoubleInteraction(this);
	}

	UFUNCTION()
	private void OpenGateTimeLikeUpdate(float CurrentValue)
	{
		RightDoorPivotComp.SetRelativeRotation(FRotator(0.0, Math::Lerp(0.0, 60.0, CurrentValue), 0.0));
		LeftDoorPivotComp.SetRelativeRotation(FRotator(0.0, Math::Lerp(0.0, -60.0, CurrentValue), 0.0));
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		RotateComp.AddRelativeRotation(FRotator(0.0, 0.0, (20.0 + RotateSpeed) * DeltaSeconds));
	}
};