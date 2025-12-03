event void FBucketSwingEvent();

class ATundra_River_SwingWithWaterBucket : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MoveRoot;

	UPROPERTY(DefaultComponent, Attach = MoveRoot)
	UStaticMeshComponent PoleMeshComp;

	UPROPERTY(DefaultComponent, Attach = MoveRoot)
	USwingPointComponent SwingPointComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BucketMoveRoot;

	UPROPERTY(DefaultComponent, Attach = BucketMoveRoot)
	USceneComponent MonkeyRoot;

	UPROPERTY(DefaultComponent, Attach = MonkeyRoot)
	UHazeSkeletalMeshComponentBase MonkeyComp;

	UPROPERTY(DefaultComponent, Attach = MonkeyRoot)
	UNiagaraComponent MonkeyWaterSplashComp;
	
	UPROPERTY(DefaultComponent, Attach = BucketMoveRoot)
	USceneComponent BucketRotateRoot;

	UPROPERTY(DefaultComponent, Attach = BucketRotateRoot)
	UStaticMeshComponent BucketMeshComp;

	UPROPERTY(DefaultComponent, Attach = BucketMoveRoot)
	UNiagaraComponent WaterSplashComp;

	UPROPERTY(DefaultComponent, Attach = BucketRotateRoot)
	UNiagaraComponent WaterLeakComp;

	UPROPERTY()
	FHazeTimeLike SwingTimeLike;

	UPROPERTY()
	FHazeTimeLike BucketTimeLike;

	UPROPERTY()
	FHazeTimeLike BucketShakeTimeLike;

	UPROPERTY()
	FHazeTimeLike MonkeyShakeTimeLike;

	UPROPERTY()
	FHazeTimeLike BucketEmptyTimeLike;
	default BucketEmptyTimeLike.Duration = 0.4;
	default BucketEmptyTimeLike.Curve.AddDefaultKey(0, 0);
	default BucketEmptyTimeLike.Curve.AddDefaultKey(1, 1);

	UPROPERTY(EditAnywhere, Category = "Bucket Swing Settings")
	FVector SwingInactiveLocation = FVector(0, 0, 550);

	UPROPERTY(EditAnywhere, Category = "Bucket Swing Settings")
	float MoveSpeed = 100;

	UPROPERTY(EditAnywhere, Category = "Bucket Swing Settings")
	bool bDebug = false;

	UPROPERTY(EditDefaultsOnly, Category = "Bucket Swing Settings")
	UAnimSequence MonkeyWaterAnimation;

	UPROPERTY(EditDefaultsOnly, Category = "Bucket Swing Settings")
	UAnimSequence DefaultMonkeyAnimation;

	FRotator DefaultSwingRotation;
	FVector DefaultBucketLocation;

	UPROPERTY()
	FBucketSwingEvent OnBucketFull;

	UPROPERTY()
	FBucketSwingEvent OnBucketReset;

	UPROPERTY()
	FBucketSwingEvent OnMonkeyCleared;

	float CurrentWaterAmount = 0;
	// Seconds it takes to fill bucket
	float MaxWaterAmount = 2;
	bool bRampAimedAtBucket = false;
	bool bIsFull = false;
	bool bIsLeaking = false;

	bool bMonkeyCleared = true; //set to true to remove monkey for now
	float MonkeyClearDuration = 2;
	float MonkeyClearTimer = 0;


	bool bShouldMove()
	{
		if(!bIsFull)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DefaultSwingRotation = MoveRoot.RelativeRotation;
		DefaultBucketLocation = BucketMoveRoot.RelativeLocation;

		OnBucketFull.AddUFunction(this, n"BucketFilled");
		OnBucketReset.AddUFunction(this, n"BucketReset");
		OnMonkeyCleared.AddUFunction(this, n"MonkeyCleared");

		SwingTimeLike.BindUpdate(this, n"SwingTimeLikeUpdate");
		SwingTimeLike.BindFinished(this, n"SwingTimeLikeFinished");
		BucketTimeLike.BindUpdate(this, n"BucketTimeLikeUpdate");
		BucketTimeLike.BindFinished(this, n"BucketTimeLikeFinished");
		BucketShakeTimeLike.BindUpdate(this, n"BucketShake");
		BucketEmptyTimeLike.BindUpdate(this, n"BucketEmptyTimeLikeUpdate");
		MonkeyShakeTimeLike.BindUpdate(this, n"MonkeyShakeTimeLikeUpdate");

		SwingPointComp.Disable(this);
	}

	UFUNCTION()
	private void MonkeyCleared()
	{
		bMonkeyCleared = true;
		MonkeyComp.SetHiddenInGame(true);
		PrintToScreen("Monkey cleared", 3);
	}

	UFUNCTION()
	private void MonkeyShakeTimeLikeUpdate(float CurrentValue)
	{
		float DesiredRotation = Math::Lerp(-20, 20, CurrentValue);
		MonkeyRoot.SetRelativeRotation(FRotator(-DesiredRotation, 75, 0));
	}

	UFUNCTION()
	private void BucketEmptyTimeLikeUpdate(float CurrentValue)
	{
		float DesiredRotation = Math::Lerp(0, -35, CurrentValue);
		BucketRotateRoot.SetRelativeRotation(FRotator(DesiredRotation, 0, 0));
	}

	UFUNCTION()
	private void BucketShake(float CurrentValue)
	{
		if(!bMonkeyCleared)
			return;

		float DesiredRotation = Math::Lerp(-7, 7, CurrentValue);
		BucketMeshComp.SetRelativeRotation(FRotator(DesiredRotation, 0, 0));
	}

	UFUNCTION()
	private void BucketTimeLikeFinished()
	{
		if(SwingTimeLike.Position == 0)
		{
			SwingTimeLike.Play();
		}
		else
		{
			SwingTimeLike.Reverse();
			SwingPointComp.Disable(this);
		}

		if(BucketTimeLike.Position == 0)
		{

		}
		else
		{
			BucketEmptyTimeLike.Play();
			WaterLeakComp.Activate();
		}
	}

	UFUNCTION()
	private void BucketTimeLikeUpdate(float CurrentValue)
	{
		FVector TargetLocation = Math::VLerp(DefaultBucketLocation, FVector(DefaultBucketLocation.X, DefaultBucketLocation.Y, DefaultBucketLocation.Z - 500), FVector(CurrentValue, CurrentValue, CurrentValue));
		BucketMoveRoot.SetRelativeLocation(TargetLocation);
	}

	UFUNCTION()
	private void SwingTimeLikeFinished()
	{
		if(SwingTimeLike.Position == 1)
		{
			SwingPointComp.Enable(this);
		}

		if(BucketTimeLike.Position == 1)
		{
			bIsLeaking = true;
		}
		else
		{
			bIsLeaking = false;
		}
	}

	UFUNCTION()
	private void SwingTimeLikeUpdate(float CurrentValue)
	{
		float DesiredPitch = Math::Lerp(0, 45, CurrentValue);
		MoveRoot.SetRelativeRotation(FRotator(DefaultSwingRotation.Pitch - (DesiredPitch), 0, 0));
	}

	UFUNCTION()
	private void BucketFilled()
	{
		BucketTimeLike.Play();
	}

	UFUNCTION()
	private void BucketReset()
	{
		BucketTimeLike.Reverse();
		WaterLeakComp.Deactivate();
		BucketEmptyTimeLike.Reverse();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bMonkeyCleared && MonkeyClearTimer < MonkeyClearDuration && bRampAimedAtBucket)
		{
			MonkeyClearTimer += DeltaSeconds;
		}
		else if(!bMonkeyCleared && MonkeyClearTimer > MonkeyClearDuration)
		{
			OnMonkeyCleared.Broadcast();
		}

		if(CurrentWaterAmount > MaxWaterAmount && !bIsFull)
		{
			bIsFull = true;
			OnBucketFull.Broadcast();
		}
		else if(CurrentWaterAmount <= 0 && bIsLeaking && bIsFull && !SwingPointComp.bIsPlayerUsingPoint[Game::GetMio()])
		{
			bIsFull = false;
			OnBucketReset.Broadcast();
		}

		if(CurrentWaterAmount <= MaxWaterAmount && bRampAimedAtBucket && bMonkeyCleared)
		{
			CurrentWaterAmount += DeltaSeconds;
		}
		else if(CurrentWaterAmount > 0 && bIsLeaking && !bRampAimedAtBucket)
		{
			CurrentWaterAmount -= DeltaSeconds * 0.7;
		}

		if(bDebug)
		{
			PrintToScreen("water: " + CurrentWaterAmount);
		}
	}

	private void StopBucketShake()
	{
		BucketShakeTimeLike.Stop();
		MonkeyShakeTimeLike.Stop();

		MonkeyClearTimer = 0;

		FHazePlaySlotAnimationParams anim;
		anim.Animation = DefaultMonkeyAnimation;
		MonkeyComp.PlaySlotAnimation(anim);

		MonkeyRoot.SetRelativeRotation(FRotator(0, 75, 0));
		BucketMeshComp.SetRelativeRotation(FRotator::ZeroRotator);
	}

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		ATundra_River_WaterslideRamp WaterSlideRampActor = Cast<ATundra_River_WaterslideRamp>(OtherActor);
		if(OtherActor == WaterSlideRampActor)
		{
			bRampAimedAtBucket = true;

			WaterSplashComp.Activate();
			if(!bMonkeyCleared)
			{
				MonkeyWaterSplashComp.Activate();
			}

			BucketShakeTimeLike.PlayFromStart();
			MonkeyShakeTimeLike.PlayFromStart();
			FHazePlaySlotAnimationParams anim;
			anim.Animation = MonkeyWaterAnimation;
			anim.PlayRate = 1.5;
			MonkeyComp.PlaySlotAnimation(anim);

			if(bDebug)
			{
				PrintToScreen("Started colliding with ramp actor", 3);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		ATundra_River_WaterslideRamp WaterSlideRampActor = Cast<ATundra_River_WaterslideRamp>(OtherActor);
		if(OtherActor == WaterSlideRampActor)
		{
			bRampAimedAtBucket = false;

			WaterSplashComp.Deactivate();
			MonkeyWaterSplashComp.Deactivate();

			StopBucketShake();

			if(bDebug)
			{
				PrintToScreen("Stopped colliding with ramp actor", 3);
			}
		}
	}
};