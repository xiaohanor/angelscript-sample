class ASkylineMallFloatingRoundBillboard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USceneComponent RollRotateRoot;

	UPROPERTY(DefaultComponent, Attach = RollRotateRoot)
	UFauxPhysicsConeRotateComponent RotateComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;

	UPROPERTY()
	FHazeTimeLike HitTimeLike;
	default HitTimeLike.UseSmoothCurveZeroToOne();
	default HitTimeLike.Duration = 2.0;

	UPROPERTY(EditAnywhere)
	float RotateSpeed = 20.0;

	float FallSpeed = 0.0;

	bool bFalling = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HitTimeLike.BindUpdate(this, n"HitTimeLikeUpdate");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bFalling)
		{
			FallSpeed += 300.0 * DeltaSeconds;
			RollRotateRoot.AddRelativeRotation(FRotator(0.0, 0.0, RotateSpeed * DeltaSeconds * 2));
			AddActorWorldOffset(FVector::UpVector * - FallSpeed * DeltaSeconds);
		}

		AddActorLocalRotation(FRotator(0.0, RotateSpeed * DeltaSeconds, 0.0));
	}

	UFUNCTION()
	void Collapse()
	{
		HitTimeLike.Play();
		bFalling = true;
		BP_Collapse();
		Timer::SetTimer(this, n"DelayedDisable", 10.0);
		USkylineMallFloatingRoundBillboardEventHandler::Trigger_OnCollapse(this);
	}
	
	UFUNCTION(BlueprintEvent)
	private void BP_Collapse(){}
	
	UFUNCTION()
	private void HitTimeLikeUpdate(float CurrentValue)
	{
		TranslateComp.SetRelativeRotation(FRotator(0.0, Math::Lerp(0.0, RotateSpeed * 10, CurrentValue), 0.0));
	}

	UFUNCTION()
	private void DelayedDisable()
	{
		AddActorDisable(this);
	}
};