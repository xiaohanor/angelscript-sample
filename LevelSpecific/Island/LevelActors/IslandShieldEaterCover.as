event void FIslandShieldEaterCoverSignature();

class AIslandShieldEaterCoverActor : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovableComp;

	UPROPERTY(EditInstanceOnly)
	AIslandOverloadShootablePanel PanelRef;
	
	UPROPERTY(EditInstanceOnly)
	AIslandOverloadShootablePanel OptionalPanelRef;
	
	UPROPERTY(EditInstanceOnly)
	AIslandOverloadPanelListener ListenerRef;

	UPROPERTY(EditInstanceOnly)
	AIslandGrenadeLockListener GrenadeListenerRef;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 1.0;
	
	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	UPROPERTY()
	FIslandShieldEaterCoverSignature OnActivated;

	UPROPERTY()
	FIslandShieldEaterCoverSignature OnReachedDestination;

	UPROPERTY()
	bool bIsPlaying;
	bool bMovingBack;
	bool bIsDisabled;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = MovableComp.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = DestinationComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		if (PanelRef != nullptr)
		{
			PanelRef.OnOvercharged.AddUFunction(this, n"HandleOvercharge");
			PanelRef.OnReset.AddUFunction(this, n"HandleReset");
		}
		if (OptionalPanelRef != nullptr)
		{
			OptionalPanelRef.OnOvercharged.AddUFunction(this, n"HandleOvercharge");
			OptionalPanelRef.OnReset.AddUFunction(this, n"HandleReset");
		}
		if (ListenerRef != nullptr)
		{
			ListenerRef.OnCompleted.AddUFunction(this, n"HandleOvercharge");
			ListenerRef.OnReset.AddUFunction(this, n"HandleReset");
			return;
		}
		if (GrenadeListenerRef != nullptr)
		{
			GrenadeListenerRef.OnCompleted.AddUFunction(this, n"HandleOvercharge");
			GrenadeListenerRef.OnReset.AddUFunction(this, n"HandleReset");
			return;
		}

	}

	UFUNCTION()
	void HandleOvercharge()
	{
		Start();
	}

	UFUNCTION()
	void HandleReset()
	{
		Reverse();
	}

	UFUNCTION()
	void Start()
	{
		MoveAnimation.Play();
		OnActivated.Broadcast();
	}

	UFUNCTION()
	void Reverse()
	{
		MoveAnimation.Reverse();

	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		if (bIsDisabled)
			return;
		
		bIsPlaying = true;
		
		SetActorLocationAndRotation(Math::Lerp(StartingPosition, EndingPosition, Alpha), FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
	}

	
	UFUNCTION()
	void OnFinished()
	{
		bIsPlaying = false;

		if(MoveAnimation.Value != 1.0)
			return;

		OnReachedDestination.Broadcast();
		
		if (CameraShake == nullptr)
			return;

		Game::GetPlayer(EHazePlayer::Mio).PlayCameraShake(CameraShake, this, 1.0);
		Game::GetPlayer(EHazePlayer::Zoe).PlayCameraShake(CameraShake, this, 1.0);

	}

	UFUNCTION()
	void DisableMovement() {
		bIsDisabled = true;
		MoveAnimation.Stop();
	}

}