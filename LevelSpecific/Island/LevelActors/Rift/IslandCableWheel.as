event void FIslandCableWheelSignature();

class AIslandCableWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UHazeMovablePlayerTriggerComponent KillTrigger;
	
	UPROPERTY(DefaultComponent, Attach = "Root")
	UHazeMovablePlayerTriggerComponent ShakeTrigger;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent RotationCW;
		
	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent RotationCCW;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;
	UHazeSplineComponent Spline;
	float DistanceAlongSpline;

	UPROPERTY(EditInstanceOnly)
	AIslandCableWheel CableSibling;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY()
	bool bShouldPlayMusic = true;
	
	UPROPERTY(BlueprintReadOnly)
	bool bIsActivated;
	
	float TravelDuration = 1.0;

	UPROPERTY(EditAnywhere)
	FVector DestinationUpVector = FVector::UpVector;

	UPROPERTY()
	FIslandCableWheelSignature OnReachedDestination;

	UPROPERTY()
	FIslandCableWheelSignature OnStartMoving;

	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 10.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Speed;
	default Speed.AddDefaultKey(0.0, 0.0);
	default Speed.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Rotation;
	default Rotation.AddDefaultKey(0.0, 0.0);
	default Rotation.AddDefaultKey(1.0, 1.0);

	UPROPERTY()
	FHazeTimeLike DelayAnimation;
	default DelayAnimation.Duration = 10.0;
	default DelayAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CamShakeClass;

	TArray<AHazePlayerCharacter> Players;
	TPerPlayer<UCameraShakeBase> CamShakeInstance;
	bool bAtEnd = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(SplineActor != nullptr)
		{
			Spline = SplineActor.Spline;
			OnUpdate(0.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(SplineActor == nullptr)
			return;
		Spline = SplineActor.Spline;
		OnUpdate(0.0);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");
		MoveAnimation.SetPlayRate(1.0 / TravelDuration);
		DelayAnimation.BindFinished(this, n"OnDelayFinished");
		KillTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnterKillTrigger");
		ShakeTrigger.OnPlayerEnter.AddUFunction(this, n"OnShakeTriggerEnter");
		ShakeTrigger.OnPlayerLeave.AddUFunction(this, n"OnShakeTriggerExit");
	}

	UFUNCTION()
	private void OnPlayerEnterKillTrigger(AHazePlayerCharacter Player)
	{
		Player.KillPlayer(DeathEffect = DeathEffect);
	}

	UFUNCTION()
	private void OnShakeTriggerEnter(AHazePlayerCharacter Player)
	{
		// auto Player = Cast<AHazePlayerCharacter>(Player);
		// if(Player == nullptr)
		// 	return;

		// Players.AddUnique(Player);

		// if (CamShakeInstance[Player] == nullptr)
		// {
		// 	CamShakeInstance[Player] = Player.PlayCameraShake(CamShakeClass, this);
		// }
	}

	UFUNCTION()
	private void OnShakeTriggerExit(AHazePlayerCharacter Player)
	{
		// if (CamShakeInstance[Player] != nullptr)
		// {
		// 	Player.StopCameraShakeInstance(CamShakeInstance[Player]);
		// 	CamShakeInstance[Player] = nullptr;
		// }

		// Players.RemoveSingleSwap(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bIsActivated)
			return;

		RotationCW.AddLocalRotation(FRotator(0,0,300) * DeltaSeconds);
		RotationCCW.AddLocalRotation(FRotator(0,0,-300) * DeltaSeconds);


		//PrintToScreen("DistanceAlongSpline" + DistanceAlongSpline);

		HandleShake();

	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		DistanceAlongSpline = Spline.SplineLength * Speed.GetFloatValue(Alpha);

		FTransform TransformAtDistance = Spline.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
		FVector CurrentLocation = TransformAtDistance.Location;
		FQuat CurrentRotation = FQuat::Slerp(TransformAtDistance.Rotation, FQuat::MakeFromZX(DestinationUpVector, TransformAtDistance.Rotation.ForwardVector), Rotation.GetFloatValue(Alpha));
		
		SetActorLocationAndRotation(CurrentLocation, CurrentRotation);

	}

	UFUNCTION()
	void OnFinished()
	{
		OnReachedDestination.Broadcast();
		UIslandCableWheelEffectHandler::Trigger_OnReachedDestination(this);
		if (bShouldPlayMusic)
			UIslandCableWheelEffectHandler::Trigger_OnReachedDestinationMusicRef(this);

		DelayAnimation.PlayFromStart();
		CableSibling.Activate();
		bAtEnd = true;
	}

	UFUNCTION()
	void OnDelayFinished()
	{
		MoveAnimation.PlayFromStart();
	}

	UFUNCTION()
	void Activate()
	{
		bIsActivated = true;
		bAtEnd = false;
		MoveAnimation.PlayFromStart();
		UIslandCableWheelEffectHandler::Trigger_OnStartMoving(this);
		OnStartMoving.Broadcast();
		if (bShouldPlayMusic)
			UIslandCableWheelEffectHandler::Trigger_OnStartMovingMusicRef(this);
	}

	UFUNCTION()
	void Deactivate()
	{
		bIsActivated = false;
		MoveAnimation.Stop();
	}

	UFUNCTION(BlueprintPure)
	float GetDistanceAlongSpline() const
	{
		return DistanceAlongSpline;
		
	}

	void HandleShake()
	{

		for(AHazePlayerCharacter Player : Game::GetPlayers())
		{
			float Dist = ActorLocation.Distance(Player.ActorLocation);
			if (Dist <= 30000 && MoveAnimation.IsPlaying())
			{
				if (CamShakeInstance[Player] == nullptr)
				{
					CamShakeInstance[Player] = Player.PlayCameraShake(CamShakeClass, this);
				}

				float ShakeScale = Math::GetMappedRangeValueClamped(FVector2D(20000, 6000), FVector2D(0.0, 1.0), Dist);
				CamShakeInstance[Player].ShakeScale = ShakeScale;

				float FFStrength = Math::Lerp(0.0, 1, ShakeScale);
				float LeftFF = Math::Sin(Time::GetGameTimeSeconds() * 10.0) * FFStrength;
				float RightFF = Math::Sin(-Time::GetGameTimeSeconds() * 10.0) * FFStrength;
				Player.SetFrameForceFeedback(LeftFF, RightFF, 0.0, 0.0);
			}
			else
			{
				if (CamShakeInstance[Player] != nullptr)
				{
					Player.StopCameraShakeInstance(CamShakeInstance[Player]);
					CamShakeInstance[Player] = nullptr;
				}
			}
		}
	}

}

UCLASS(Abstract)
class UIslandCableWheelEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedDestination() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMovingMusicRef() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedDestinationMusicRef() {}
}