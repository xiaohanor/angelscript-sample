event void FIslandFlippingDangerPlatformSignature();

class AIslandFlippingDangerPlatform : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovableComp;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent CollisionBox;

	UPROPERTY(EditAnywhere)
	bool bAutoPlay;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 0.9;
	
	UPROPERTY(EditAnywhere)
	float DelayDuration = 4;

	UPROPERTY(EditAnywhere)
	float OffsetDuration = SMALL_NUMBER;
	
	UPROPERTY()
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	
	UPROPERTY()
	FHazeTimeLike  OffsetDelayAnimation;
	default OffsetDelayAnimation.Duration = 1.0;
	default OffsetDelayAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY()
	FHazeTimeLike  DelayAnimation;
	default DelayAnimation.Duration = 1.0;
	default DelayAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;
	bool bMovingUp;

	UPROPERTY()
	FIslandFlippingDangerPlatformSignature OnActivated;

	UPROPERTY()
	FIslandFlippingDangerPlatformSignature OnReachedDestination;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveAnimation.Duration =  AnimationDuration;
		StartingTransform = MovableComp.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = DestinationComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		OffsetDelayAnimation.BindUpdate(this, n"OnOffsetUpdate");
		OffsetDelayAnimation.BindFinished(this, n"OnOffsetFinished");

		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		DelayAnimation.BindUpdate(this, n"OnDelayUpdate");
		DelayAnimation.BindFinished(this, n"OnDelayFinished");

		if (OffsetDuration == 0)
			OffsetDuration = SMALL_NUMBER;

		OffsetDelayAnimation.SetPlayRate(1.0 / OffsetDuration);
		DelayAnimation.SetPlayRate(1.0 / DelayDuration);
		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		
		CollisionBox.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
		CollisionBox.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");

		if (bAutoPlay)
			ActivatePlatform();

	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	
		if (bMovingUp)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player == nullptr)
			return;

		Player.DamagePlayerHealth(1.0);

	}

	UFUNCTION()
	private void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{	
		// if (bIsCompleted)
		// 	return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != Game::GetPlayer(EHazePlayer::Mio) || Player  != Game::GetPlayer(EHazePlayer::Zoe))
			return;

	}

	UFUNCTION()
	void ActivatePlatform()
	{
		OffsetDelayAnimation.PlayFromStart();
	}

	UFUNCTION()
	void Start()
	{
		MoveAnimation.PlayFromStart();
		UIslandFlippingDangerPlatformEffectHandler::Trigger_OnStartMovingDown(this);
		bMovingUp = false;
	}

	UFUNCTION()
	void Reverse()
	{
		MoveAnimation.ReverseFromEnd();
		UIslandFlippingDangerPlatformEffectHandler::Trigger_OnStartMovingUp(this);
		bMovingUp = true;
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		SetActorLocationAndRotation(Math::Lerp(StartingPosition, EndingPosition, Alpha), FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
	}

	UFUNCTION()
	void OnOffsetUpdate(float Alpha)
	{
		// SetActorLocationAndRotation(Math::Lerp(StartingPosition, EndingPosition, Alpha), FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
		
	}

	UFUNCTION()
	void OnOffsetFinished()
	{
		OnActivated.Broadcast();
		MoveAnimation.PlayFromStart();
	}
	
	UFUNCTION()
	void OnFinished()
	{
		DelayAnimation.PlayFromStart();
	}

	UFUNCTION()
	void OnDelayUpdate(float Alpha)
	{
		// PrintToScreen("delay",0.1);
		if (Alpha > 0.7)
			BP_GoingToMove();
	}

		
	UFUNCTION()
	void OnDelayFinished()
	{
		if(MoveAnimation.Value == 1.0)
		{
			Reverse();
			OnReachedDestination.Broadcast();
		} 
		else 
		{
			Start();
		}

	}

	UFUNCTION(BlueprintEvent)
	void BP_GoingToMove() {}

	// Get the alpha of the current position of the moving platform, between 0 and 1. 0 is bottom and 1 is top
	UFUNCTION(BlueprintPure)
	float GetPositionAlpha() const
	{
		return 1.0 - MoveAnimation.Value;
	}
	
	// Get the movement direction of the moving platform, 1 is up and -1 is down, 0 is not moving.
	UFUNCTION(BlueprintPure)
	int GetMoveDirection() const
	{
		if(!MoveAnimation.IsPlaying())
			return 0;

		return bMovingUp ? 1 : -1;
	}

}

UCLASS(Abstract)
class UIslandFlippingDangerPlatformEffectHandler : UHazeEffectEventHandler
{
	// Triggers when the moving platform starts moving upwards
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMovingUp() {}

	// Triggers when the moving platform starts moving downwards
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMovingDown() {}
}