event void FSummitTreasureTempleCrumblePlatformSignature();

class ASummitTreasureTempleCrumblePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;
	
	UPROPERTY()
	UNiagaraSystem Effect;

	bool bIsDeactivated;
	bool bActivateShake;

	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 4;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FHazeTimeLike DelayTimer;	
	default DelayTimer.Duration = 1.2;
	default DelayTimer.UseLinearCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FRuntimeFloatCurve ShakeCurve;
	default ShakeCurve.AddDefaultKey(0,0);
	default ShakeCurve.AddDefaultKey(1, 1);

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ShakeMaxMagnitude = 8;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ShakeDuration = 1.4;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector ShakeFrequency = FVector(-29.0, 37.0, 12.0);

	FVector StartRelativeLocation;

	private float Timer = 0.0;
	private bool bLandedDuringMovement = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = Root.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		StartRelativeLocation = BaseComp.GetRelativeLocation();

		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");
		MoveAnimation.SetPlayRate(1.0);

		DelayTimer.BindFinished(this, n"OnDelayFinished");

		ImpactComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnImpacted");

		EndingTransform =  DestinationComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

	}

	UFUNCTION()
	private void OnImpacted(AHazePlayerCharacter Player)
	{
		if(MoveAnimation.IsPlaying()
		&& MoveAnimation.IsReversed())
		{
			bLandedDuringMovement = true;
			return;
		}

		if (bIsDeactivated)
			return;

		if (MoveAnimation.IsPlaying())
			return;

		if (DelayTimer.IsPlaying())
			return;

		StartShaking();
	}

	private void StartShaking()
	{
		Timer = 0;
		DelayTimer.PlayFromStart();
		bActivateShake = true;

		USummitTreasureTempleCrumblePlatformEventHandler::Trigger_OnStartShaking(this);
		BP_OnActivated();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bLandedDuringMovement)
		{
			StartShaking();
			bLandedDuringMovement = false;
		}

		if (!bActivateShake)
			return;

		Timer += DeltaSeconds;
		
		if(Timer >= ShakeDuration)
		{
			bActivateShake = false;
			USummitTreasureTempleCrumblePlatformEventHandler::Trigger_OnStopShaking(this);
			return;
		}

		float CurveMultiplier = ShakeCurve.GetFloatValue(Timer/ShakeDuration);
		float ShakeAmountX = Math::Sin(Timer * ShakeFrequency.X) * CurveMultiplier * ShakeMaxMagnitude;
		float ShakeAmountY = Math::Sin(Timer * ShakeFrequency.Y) * CurveMultiplier * ShakeMaxMagnitude;
		float ShakeAmountZ = Math::Sin(Timer * ShakeFrequency.Z) * CurveMultiplier * ShakeMaxMagnitude;
		FVector ShakeOffset = FVector(ShakeAmountX, ShakeAmountY, ShakeAmountZ);
		FVector NewRelativeLocation = StartRelativeLocation + ShakeOffset;
		BaseComp.SetRelativeLocation(NewRelativeLocation);
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		SetActorLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
	}

	UFUNCTION()
	void OnFinished()
	{
		if (MoveAnimation.Value == 1)
			Respawn();

		if (MoveAnimation.Value == 0)
		{
			MoveAnimation.SetPlayRate(1);
			USummitTreasureTempleCrumblePlatformEventHandler::Trigger_OnStopResetting(this);
		}
		
	}

	UFUNCTION()
	void OnDelayFinished()
	{
		MoveAnimation.PlayFromStart();
		USummitTreasureTempleCrumblePlatformEventHandler::Trigger_OnStartDropping(this);
	}

	UFUNCTION()
	void Respawn()
	{
		bActivateShake = false;
		MoveAnimation.SetPlayRate(5);
		MoveAnimation.Reverse();
		BP_OnRespawn();
		BaseComp.SetRelativeLocation(StartRelativeLocation);
		USummitTreasureTempleCrumblePlatformEventHandler::Trigger_OnStartResetting(this);
	}

	UFUNCTION()
	void DeactivatePlatform()
	{
		MoveAnimation.Reverse();
		bIsDeactivated = true;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivated() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnRespawn() {}

}
