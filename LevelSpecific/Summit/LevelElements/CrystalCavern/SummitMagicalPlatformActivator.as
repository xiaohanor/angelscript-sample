event void FSummitMagicalPlatformActivatorSignature();

class ASummitMagicalPlatformActivator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovableComp;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 2.0;

	UPROPERTY(EditAnywhere)
	bool bAutoReverse = true;
		
	UPROPERTY(EditAnywhere)
	float DelayDuration = 2;
	
	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	bool bActivateWithAcid = true;

	UPROPERTY()
	float AcidHealth = 2;
	float CurrentAcidHealth = AcidHealth;

	UPROPERTY(EditInstanceOnly)
	bool bIsAttachedToParent;
	
	bool bActivateWithTail;
	
	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ASummitMagicalRollPlatform> Children;
	int ChildCount;

	UPROPERTY(EditAnywhere, Category = "Setup")
	float BobHeight = 50.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	float BobSpeed = 2.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	float BobOffset = 0.0;
	
	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedGameTime;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedBobbingRotation;

	UPROPERTY()
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 1.0;
	// default MoveAnimation.UseSmoothCurveZeroToOne();
	default MoveAnimation.UseLinearCurveZeroToOne();

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailResponseComp;

	FTransform StartingTransform;

	UPROPERTY()
	FQuat StartingRotation;

	UPROPERTY()
	FVector StartingPosition;
	FTransform EndingTransform;

	UPROPERTY()
	FQuat EndingRotation;
	UPROPERTY()
	FVector EndingPosition;

	UPROPERTY()
	FSummitMagicalPlatformActivatorSignature OnActivated;

	UPROPERTY()
	FSummitMagicalPlatformActivatorSignature OnReachedDestination;

	UPROPERTY()
	FSummitMagicalPlatformActivatorSignature OnReset;
	
	UPROPERTY()
	FHazeTimeLike  DelayAnimation;
	default DelayAnimation.Duration = 1.0;
	default DelayAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY()
	bool bIsPlaying;
	bool bIsDisabled;

	UPROPERTY(EditAnywhere)
	bool bOneTimeUse;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bIsAttachedToParent)
		{
			StartingTransform = GetActorRelativeTransform();
			// GetRelativeTransform();
			StartingPosition = StartingTransform.GetLocation();
			StartingRotation = StartingTransform.GetRotation();

			EndingTransform = DestinationComp.GetRelativeTransform();
			EndingPosition = EndingTransform.GetLocation();
			EndingRotation = EndingTransform.GetRotation();
		}
		else 
		{
			StartingTransform = MovableComp.GetWorldTransform();
			StartingPosition = StartingTransform.GetLocation();
			StartingRotation = StartingTransform.GetRotation();

			EndingTransform = DestinationComp.GetWorldTransform();
			EndingPosition = EndingTransform.GetLocation();
			EndingRotation = EndingTransform.GetRotation();
		}
		

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		DelayAnimation.BindUpdate(this, n"OnDelayUpdate");
		DelayAnimation.BindFinished(this, n"OnDelayFinished");

		if (DelayDuration == 0)
			DelayDuration = SMALL_NUMBER;

		DelayAnimation.SetPlayRate(1.0 / DelayDuration);

		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		TailResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");

		ChildCount = Children.Num();

		if(HasControl())
		{
			SyncedGameTime.Value = Time::GameTimeSeconds;
			SyncedBobbingRotation.Value = MovableComp.RelativeRotation;
		}

	}

	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

		if(HasControl())
			SyncedGameTime.Value = Time::GameTimeSeconds;

		if (bIsPlaying)
			return;

		MovableComp.SetRelativeLocation(FVector::UpVector * Math::Sin((SyncedGameTime.Value * BobSpeed + BobOffset)) * BobHeight);
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Param)
	{
        if (!bActivateWithAcid)
            return;

		CurrentAcidHealth = CurrentAcidHealth - 0.25;

		if (!bIsPlaying)
			BP_OnImpact();

		if (bIsPlaying)
			return;

		// MovableComp.AddLocalRotation(FRotator(0, 2, 0));

		if (CurrentAcidHealth <= 0)
	        Start();
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if (!bActivateWithTail)
        	return;

		Start();
	}

	UFUNCTION()
	void Start()
	{
		if (bIsDisabled)
			return;

		MoveAnimation.Play();
		OnActivated.Broadcast();
		BP_OnActivated();
		bIsPlaying = true;
	}

	UFUNCTION()
	void Reverse()
	{
		if (bIsDisabled)
			return;

		MoveAnimation.Reverse();
		bIsPlaying = false;
		BP_OnReverse();
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		if (bIsDisabled)
			return;

		// MovableComp.AddLocalRotation(FRotator(0, 1, 0));

		if (bIsAttachedToParent)
		{
			// SetActorRelativeLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
			// SetActorRelativeRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
		}
		else
		{
			SetActorLocationAndRotation(Math::Lerp(StartingPosition, EndingPosition, Alpha), FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
		}

	}

	UFUNCTION()
	void OnFinished()
	{

		if (MoveAnimation.Value == 0)
			BP_OnReset(); OnReset.Broadcast();

		if(MoveAnimation.Value != 1.0)
			return;

		if (bActivateWithAcid)
			CurrentAcidHealth = AcidHealth;

		OnReachedDestination.Broadcast();
		BP_OnRecachedDestination();

		if (bAutoReverse)
			DelayAnimation.PlayFromStart();
		
		if (CameraShake == nullptr)
			return;

		Game::GetPlayer(EHazePlayer::Mio).PlayCameraShake(CameraShake, this, 1.0);
		Game::GetPlayer(EHazePlayer::Zoe).PlayCameraShake(CameraShake, this, 1.0);
	}

	UFUNCTION()
	void OnDelayUpdate(float Alpha)
	{
		// MovableComp.AddLocalRotation(FRotator(0, 1, 0));
	}
		
	UFUNCTION()
	void OnDelayFinished()
	{

		if(MoveAnimation.Value == 1.0)
		{
			Reverse();

			if (ChildCount != 0) 
			{
				for (auto Child : Children)
				{
					Child.Reverse();
				}
			}
		} 
	}

	UFUNCTION()
	void DisableMovement() 
	{
		bIsDisabled = true;
	}

	UFUNCTION()
	void ActivateChildren()
	{
		if (ChildCount != 0) 
		{
			for (auto Child : Children)
			{
				if (Child != nullptr)
					Child.Start();
			}
		}
	}

	
	UFUNCTION(BlueprintEvent)
	void BP_OnImpact(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivated(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnRecachedDestination(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnReverse(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnReset(){}

}
