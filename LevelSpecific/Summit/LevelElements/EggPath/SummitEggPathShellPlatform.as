event void FSummitEggPathShellPlatformSignature();

class ASummitEggPathShellPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndingPositionComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MovableObject;

	UPROPERTY(DefaultComponent, Attach = MovableObject)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedGameTime;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedBobbingRotation;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;
	
	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere)
	float DelayDuration = 1.0;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 3.0;

	UPROPERTY(EditAnywhere)
	float EffectDuration = 5.0;

	UPROPERTY(EditAnywhere)
	float BobHeight = 40.0;

	UPROPERTY(EditAnywhere)
	float BobSpeed = 0.4;

	UPROPERTY(EditAnywhere)
	float BobOffset = 0.0;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	bool bIsPlaying;

	bool bShouldBob;

	UPROPERTY()
	FSummitEggPathShellPlatformSignature OnMoving;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = Pivot.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = EndingPositionComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		if (DelayDuration == 0)
			DelayDuration = SMALL_NUMBER;

		BobOffset = (BobOffset * 3 + 1) / 2;

		if(HasControl())
		{
			SyncedGameTime.Value = Time::GameTimeSeconds;
		}

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bShouldBob)
			return;

		if(HasControl())
			SyncedGameTime.Value = Time::GameTimeSeconds;

		MovableObject.SetRelativeLocation(FVector::UpVector * Math::Sin((SyncedGameTime.Value * BobSpeed + BobOffset)) * BobHeight);

	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		bIsPlaying = true;

		Pivot.SetWorldLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		Pivot.SetWorldRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));

	}

	
	UFUNCTION()
	void OnFinished()
	{
		bIsPlaying = false;

		if (MoveAnimation.IsReversed())
		{
			UASummitEggPathShellPlatformEffectHandler::Trigger_EggShellReverseCompleted(this);
			if (CameraShake == nullptr)
				return;

			MoveAnimation.SetPlayRate(1);

			Game::Mio.PlayWorldCameraShake(CameraShake, this, ActorLocation, 1000, 4000);
			Game::Zoe.PlayWorldCameraShake(CameraShake, this, ActorLocation, 1000, 4000);
		}
		else
		{
			UASummitEggPathShellPlatformEffectHandler::Trigger_EggShellCompleted(this);
		}

		

	}

	UFUNCTION()
	void ActivateEggPlatform()
	{
		// Timer::SetTimer(this, n"HandleEffectCompleted", EffectDuration);
		Timer::SetTimer(this, n"StartPlatformAnimation", DelayDuration);
	}

	UFUNCTION()
	void HandleEffectCompleted()
	{
		UASummitEggPathShellPlatformEffectHandler::Trigger_EggShellEffectCompleted(this);
	}

	UFUNCTION()
	void StartPlatformAnimation()
	{
		OnMoving.Broadcast();
		MoveAnimation.Play();
		bShouldBob = true;
		UASummitEggPathShellPlatformEffectHandler::Trigger_EggShellStartMove(this);
	}

	UFUNCTION()
	void ReverseEggPlatform()
	{
		bShouldBob = false;
		MoveAnimation.SetPlayRate(3);
		MoveAnimation.Reverse();
		HandleEffectCompleted();
		UASummitEggPathShellPlatformEffectHandler::Trigger_EggShellStartReverse(this);
	}

};

UCLASS(Abstract)
class UASummitEggPathShellPlatformEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void EggShellStartMove() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void EggShellEffectCompleted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void EggShellCompleted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void EggShellStartReverse() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void EggShellReverseCompleted() {}


}