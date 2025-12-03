event void FOnOilRigForceFieldSpinnerBrokenRotate();

class AOilRigForceFieldSpinner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SpinnerRoot;

	UPROPERTY(DefaultComponent, Attach = SpinnerRoot)
	USceneComponent OpeningRoot;

	UPROPERTY(DefaultComponent, Attach = OpeningRoot)
	UStaticMeshComponent OpeningMesh;

	UPROPERTY(DefaultComponent, Attach = SpinnerRoot)
	USceneComponent FirstHoleRoot;

	UPROPERTY(DefaultComponent, Attach = SpinnerRoot)
	USceneComponent SecondHoleRoot;

	UPROPERTY(DefaultComponent, Attach = FirstHoleRoot)
	USphereComponent FirstHolePlayerTrigger;

	UPROPERTY(DefaultComponent, Attach = SecondHoleRoot)
	USphereComponent SecondHolePlayerTrigger;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent KillTrigger;

	UPROPERTY(DefaultComponent, Attach = SpinnerRoot)
	UBoxComponent AudioPlane1;

	UPROPERTY(DefaultComponent, Attach = SpinnerRoot)
	UBoxComponent AudioPlane2;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 12000;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedRotComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike BrokenTimeLike;

	UPROPERTY()
	FOnOilRigForceFieldSpinnerBrokenRotate OnBrokenRotate;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve OpacityCurve;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditAnywhere)
	float RotationSpeed = 40.0;

	float MinSpeed = 40.0;
	float MaxSpeed = 120.0;

	float Rotation = 0.0;
	
	float BrokenStartRot = 0.0;
	float BrokenTargetRot = 0.0;

	bool bBroken = false;

	bool bSafeZonesActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		KillTrigger.OnComponentBeginOverlap.AddUFunction(this, n"PlayerEnter");

		BrokenTimeLike.BindUpdate(this, n"UpdateBroken");
		BrokenTimeLike.BindFinished(this, n"FinishBroken");
	}

	UFUNCTION()
	private void PlayerEnter(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (bSafeZonesActive)
		{
			if (FirstHolePlayerTrigger.IsOverlappingActor(Player) || SecondHolePlayerTrigger.IsOverlappingActor(Player))
				return;
		}

		float Dot = (Player.ActorLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal().DotProduct(ActorForwardVector);
		FVector DeathDirection = Dot > 0.0 ? ActorForwardVector : -ActorForwardVector;
		Player.KillPlayer(FPlayerDeathDamageParams(DeathDirection), DeathEffect);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bBroken)
			return;

		if (HasControl())
		{
			Rotation = Math::Wrap(Rotation - (RotationSpeed * DeltaTime), 0.0, 360.0);
			SyncedRotComp.SetValue(FRotator(0.0, 0.0, Rotation));
		}

		SpinnerRoot.SetRelativeRotation(SyncedRotComp.Value);

		float SpeedAlpha = Math::GetMappedRangeValueClamped(FVector2D(MinSpeed, MaxSpeed), FVector2D(0.0, 1.0), RotationSpeed);
		float OpacityValue = OpacityCurve.GetFloatValue(SpeedAlpha);
		OpeningMesh.SetScalarParameterValueOnMaterialIndex(0, n"MasterOpacity", OpacityValue);

		if (SpeedAlpha <= 0.1)
			ActivateSafeZones();
		else
			DeactivateSafeZones();
	}

	void ActivateSafeZones()
	{
		if (bSafeZonesActive)
			return;

		bSafeZonesActive = true;
	}

	void DeactivateSafeZones()
	{
		if (!bSafeZonesActive)
			return;

		if (bBroken)
			return;

		bSafeZonesActive = false;
	}

	UFUNCTION()
	void Break()
	{
		if (bBroken)
			return;

		bBroken = true;
		Timer::SetTimer(this, n"DelayedBreak", 0.3);
	}

	UFUNCTION()
	private void DelayedBreak()
	{
		BrokenStartRot = BrokenTargetRot;
		BrokenTargetRot = Math::Wrap(BrokenStartRot + 90.0, 0.0, 360.0);
		BrokenTimeLike.PlayFromStart();

		OpeningMesh.SetScalarParameterValueOnMaterialIndex(0, n"MasterOpacity", 0.0);
		
		ActivateSafeZones();
		OnBrokenRotate.Broadcast();
	}

	UFUNCTION()
	private void UpdateBroken(float CurValue)
	{
		FRotator Rot = Math::LerpShortestPath(FRotator(0.0, 0.0, BrokenStartRot), FRotator(0.0, 0.0, BrokenTargetRot), CurValue);
		SpinnerRoot.SetRelativeRotation(Rot);
	}

	UFUNCTION()
	private void FinishBroken()
	{
		BrokenStartRot = BrokenTargetRot;
		BrokenTargetRot = Math::Wrap(BrokenStartRot - 90.0, 0.0, 360.0);
		BrokenTimeLike.PlayFromStart();
		OnBrokenRotate.Broadcast();
	}
}