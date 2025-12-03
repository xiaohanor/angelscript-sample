event void FMonkeyHatchEvent();

UCLASS(Abstract)
class ATundra_MonkeyHatches : AHazeActor
{
	UPROPERTY(EditInstanceOnly)
	ATundra_MonkeyHatchSlamPlatform SlamPlatform;

	UPROPERTY(EditInstanceOnly)
	ATundra_MonkeyHatchDrum Drum;

	UPROPERTY(EditAnywhere)
	float HatchClosedDuration = 5;
	
	UPROPERTY(EditAnywhere)
	float DistractionDuration = 3;

	UPROPERTY()
	FHazePlaySlotAnimationParams AttackAnimation;

	UPROPERTY()
	FHazePlaySlotAnimationParams IdleAnimation;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = InnerHatchMeshRoot)
	UHazeSkeletalMeshComponentBase InnerMonkeyMeshComp;
	
	UPROPERTY(DefaultComponent, Attach = OuterHatchMeshRoot)
	UHazeSkeletalMeshComponentBase OuterMonkeyMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent InnerHatchMeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent OuterHatchMeshRoot;

	UPROPERTY(DefaultComponent, Attach = InnerHatchMeshRoot)
	USceneComponent InnerHatchRootOffset;

	UPROPERTY(DefaultComponent, Attach = InnerHatchRootOffset)
	USceneComponent InnerHatchRoot;

	UPROPERTY(DefaultComponent, Attach = InnerHatchRoot)
	USceneComponent	InnerHatchShakeRoot;

	UPROPERTY(DefaultComponent, Attach = OuterHatchMeshRoot)
	USceneComponent OuterHatchRootOffset;
	
	UPROPERTY(DefaultComponent, Attach = OuterHatchRootOffset)
	USceneComponent OuterHatchRoot;

	UPROPERTY(DefaultComponent, Attach = OuterHatchRoot)
	USceneComponent	OuterHatchShakeRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent OuterSpearRoot;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent InnerSpearRoot;

	UPROPERTY(DefaultComponent, Attach = InnerSpearRoot)
	USceneComponent InnerSpearOffsetRoot;
	
	UPROPERTY(DefaultComponent, Attach = OuterSpearRoot)
	USceneComponent OuterSpearOffsetRoot;

	UPROPERTY(DefaultComponent, Attach = InnerSpearOffsetRoot)
	UStaticMeshComponent InnerSpear;

	UPROPERTY(DefaultComponent, Attach = OuterSpearOffsetRoot)
	UStaticMeshComponent OuterSpear;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent InnerKillTriggerComp;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent OuterKillTriggerComp;

	UPROPERTY()
	FMonkeyHatchEvent OnMonkeyAlertedEvent;

	UPROPERTY()
	FMonkeyHatchEvent OnMonkeyRecoveredEvent;

	bool bZoeInTrigger = false;
	bool bMonkeyAlerted = false;
	bool bIsClosed = false;
	float ClosedTimer = 0;
	float DistractedTimer = 0;
	bool bPermanentlyClosed = false;

	FHazeAnimationDelegate InnerAttackBlendOut;
	FHazeAnimationDelegate InnerAttackBlendIn;
	FHazeAnimationDelegate OuterAttackBlendOut;
	FHazeAnimationDelegate OuterAttackBlendIn;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InnerKillTriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"OnInnerKillTriggerEntered");
		OuterKillTriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"OnOuterKillTriggerEntered");
		InnerAttackBlendOut.BindUFunction(this, n"OnInnerAttackAnimationFinished");
		OuterAttackBlendOut.BindUFunction(this, n"OnOuterAttackAnimationFinished");

		ToggleInnerHatch(false);
		ToggleOuterHatch(false);
		ToggleMonkeys(true);
		// ToggleMonkeyAlerted(false);

		InnerMonkeyMeshComp.PlaySlotAnimation(IdleAnimation);
		OuterMonkeyMeshComp.PlaySlotAnimation(IdleAnimation);

		if(SlamPlatform != nullptr)
		{
			// SlamPlatform.OnGroundSlammed.AddUFunction(this, n"OnSlamPlatformSlammed");
		}

		if(Drum != nullptr)
		{
			Drum.OnDrumHit.AddUFunction(this, n"OnDrumHit");
		}
	}

	UFUNCTION()
	private void OnDrumHit()
	{
		PermanentlyHideMonkeys();
		CloseHatches();

		// if(bMonkeyAlerted)
		// 	return;
		
		// ToggleMonkeyAlerted(true);
		// DistractedTimer = DistractionDuration;
	}

	UFUNCTION(BlueprintPure)
	bool BP_GetMonkeyAlerted()
	{
		return bMonkeyAlerted;
	}

	UFUNCTION()
	void BP_PermanentlyCloseHatches()
	{
		CloseHatches(true);
	}

	UFUNCTION()
	void PermanentlyHideMonkeys()
	{
		ToggleMonkeys(false);
	}

	UFUNCTION()
	private void OnOuterAttackAnimationFinished()
	{
		OuterMonkeyMeshComp.PlaySlotAnimation(IdleAnimation);
	}

	UFUNCTION()
	private void OnInnerAttackAnimationFinished()
	{
		InnerMonkeyMeshComp.PlaySlotAnimation(IdleAnimation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(ClosedTimer > 0 && !bPermanentlyClosed)
		{
			// ClosedTimer -= DeltaSeconds;
		}

		if(ClosedTimer <= 0 && bIsClosed)
		{
			OpenHatches();
		}

		if(DistractedTimer > 0 && !bPermanentlyClosed)
		{
			//DistractedTimer -= DeltaSeconds;
		}
		else
		{
			if(bMonkeyAlerted)
			{
				ToggleMonkeyAlerted(false);
			}
		}

		if(bIsClosed && !bPermanentlyClosed)
		{
			float SineRotate = Math::Sin(Time::GetGameTimeSeconds() * 50) * 4;
			InnerHatchShakeRoot.RelativeRotation = FRotator(Math::Sin(Time::GetGameTimeSeconds() * 3), 0, Math::Sin(Time::GetGameTimeSeconds() * 5)) * SineRotate;
			OuterHatchShakeRoot.RelativeRotation = FRotator(Math::Sin(Time::GetGameTimeSeconds() * 3), 0, Math::Sin(Time::GetGameTimeSeconds() * 5)) * SineRotate;
		}
	}

	UFUNCTION()
	private void CloseHatches(bool bPermanent = false)
	{
		if(bPermanent)
		{
			bPermanentlyClosed = true;
		}

		if(bIsClosed && !bPermanent)
			return;

		bIsClosed = true;

		ClosedTimer = HatchClosedDuration;

		InnerKillTriggerComp.SetGenerateOverlapEvents(false);
		OuterKillTriggerComp.SetGenerateOverlapEvents(false);

		InnerHatchShakeRoot.RelativeRotation = FRotator::ZeroRotator;
		OuterHatchShakeRoot.RelativeRotation = FRotator::ZeroRotator;

		ToggleInnerHatch(false);
		ToggleOuterHatch(false);
	}

	UFUNCTION()
	private void OpenHatches()
	{
		if(!bIsClosed || bPermanentlyClosed)
			return;

		bIsClosed = false;
	}

	UFUNCTION()
	void ToggleMonkeys(bool bEnable = true)
	{
		OuterKillTriggerComp.SetGenerateOverlapEvents(bEnable);
		ToggleOuterHatch(bEnable);

		InnerKillTriggerComp.SetGenerateOverlapEvents(bEnable);
		ToggleInnerHatch(bEnable);
	}

	UFUNCTION()
	private void ToggleMonkeyAlerted(bool bAlerted)
	{
		if(bPermanentlyClosed)
			return;

		OuterKillTriggerComp.SetGenerateOverlapEvents(!bAlerted);
		ToggleOuterHatch(!bAlerted);

		InnerKillTriggerComp.SetGenerateOverlapEvents(bAlerted);
		ToggleInnerHatch(bAlerted);

		bMonkeyAlerted = bAlerted;

		if(bAlerted)
		{
			OnMonkeyAlertedEvent.Broadcast();
		}
		else
		{
			OnMonkeyRecoveredEvent.Broadcast();
		}
	}

	UFUNCTION()
	private void ToggleInnerHatch(bool bOpen)
	{
		InnerMonkeyMeshComp.SetHiddenInGame(!bOpen);
		InnerSpear.SetHiddenInGame(!bOpen);
		InnerHatchRoot.SetRelativeRotation(FRotator(0, bOpen ? -145 : 0, 0));
	}

	UFUNCTION()
	private void ToggleOuterHatch(bool bOpen)
	{
		OuterMonkeyMeshComp.SetHiddenInGame(!bOpen);
		OuterSpear.SetHiddenInGame(!bOpen);
		OuterHatchRoot.SetRelativeRotation(FRotator(0, bOpen ? 145 : 0, 0));
	}

	UFUNCTION()
	private void OnSlamPlatformSlammed()
	{
		PermanentlyHideMonkeys();
		CloseHatches();
	}

	UFUNCTION()
	private void OnInnerKillTriggerEntered(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                       UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                       bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		Player.KillPlayer();
		InnerMonkeyMeshComp.PlaySlotAnimation(InnerAttackBlendIn, InnerAttackBlendOut, AttackAnimation);
	}

	UFUNCTION()
	private void OnOuterKillTriggerEntered(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                   UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                   const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		Player.KillPlayer();
		OuterMonkeyMeshComp.PlaySlotAnimation(OuterAttackBlendIn, OuterAttackBlendOut, AttackAnimation);
	}
};