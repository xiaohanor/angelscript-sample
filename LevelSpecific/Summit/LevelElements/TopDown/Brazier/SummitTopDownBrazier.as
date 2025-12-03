event void FCompleteStateForVO();

class ASummitTopDownBrazier : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRootComp;

	UPROPERTY(DefaultComponent, Attach =  MeshRootComp)
	UStaticMeshComponent AcidResponseMesh;

	UPROPERTY(DefaultComponent, Attach =  MeshRootComp)
	UStaticMeshComponent TailResponseMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRootComp)
	USceneComponent MovingRootComp;

	UPROPERTY(DefaultComponent, Attach = MovingRootComp)
	USceneComponent LeftWingComp;
	
	UPROPERTY(DefaultComponent, Attach = MovingRootComp)
	USceneComponent RightWingComp;

    UPROPERTY(DefaultComponent)
	USceneComponent ActivatedLocation;
    FVector StartLocation;
    FVector EndLocation;
	FRotator StartRotationLeft;
	FRotator EndRotationLeft;
	FRotator StartRotationRight;
	FRotator EndRotationRight;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(DefaultComponent, Attach = AcidResponseMesh)
	UAcidResponseComponent AcidResponseComp;
	
	UPROPERTY()
	ASummitTopDownBrazierListener Parent;

    bool bAcidResponse = true;

	UPROPERTY(EditAnywhere)
    float AcidHP = 100;

	UPROPERTY(EditAnywhere)
    float AcidDamagePerHit = 10;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 1;

	UPROPERTY(EditAnywhere)
	float TimeUntilReset = 5;
	float TimeUntilResetTimer;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike MoveAnimation;
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

    UPROPERTY(BlueprintReadOnly)
	bool bFinishedAnimation;

	UPROPERTY(BlueprintReadOnly)
	bool bActivated;

	UPROPERTY(BlueprintReadOnly)
	bool bCompleted;

	UPROPERTY()
	FCompleteStateForVO StatueIsActive;

	UPROPERTY()
	FCompleteStateForVO StatueIsInactive;

    float CurrentHP;
	bool bAcidHits;
	bool bAllowAcidHits;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeUntilResetTimer = TimeUntilReset;

        StartLocation = MovingRootComp.GetRelativeLocation();
        EndLocation = ActivatedLocation.GetRelativeLocation();

		StartRotationLeft = LeftWingComp.GetRelativeRotation();
		EndRotationLeft = FRotator(0,-45,0);

		StartRotationRight = RightWingComp.GetRelativeRotation();
		EndRotationRight = FRotator(0,45,0);

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		// TailResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");

		SetActorTickEnabled(false);

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bActivated)
			return;

		if(bCompleted)
			return;

		TimeUntilResetTimer = TimeUntilResetTimer - DeltaSeconds;
		if (TimeUntilResetTimer <= 0)
		{
			ReverseAnimation();
		}

	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		// MovingRootComp.SetRelativeLocation(Math::Lerp(StartLocation, EndLocation, Alpha));
		LeftWingComp.SetRelativeRotation(Math::LerpShortestPath(StartRotationLeft, EndRotationLeft, Alpha));
		RightWingComp.SetRelativeRotation(Math::LerpShortestPath(StartRotationRight, EndRotationRight, Alpha));

	}

	UFUNCTION()
	void StartAnimation()
	{
		// NOTE: Audio still wants the event even though an animation is still playing.
		// if(!MoveAnimation.IsPlaying())
		USummitTopDownBrazierEventHandler::Trigger_OnWingsStartedMovingOut(this);

        MoveAnimation.Play();
		BP_OnActivated();

		if(Parent.GetCompletionAlpha() == 1)
			USummitTopDownBrazierEventHandler::Trigger_OnFinished(this);
			
	}

	UFUNCTION()
	void ReverseAnimation()
	{
		MoveAnimation.Reverse();
		bActivated = false;
		SetActorTickEnabled(false);
		TimeUntilResetTimer = TimeUntilReset;
		CurrentHP = 0;
		BP_OnDeactivated();

		USummitTopDownBrazierEventHandler::Trigger_OnWingsStartedMovingBack(this);
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit AcidHit)
	{
		if (!bAcidResponse)
			return;

		FSummitTopDownBrazierOnHitByAcidParams Params;
		Params.AlphaToCompletion = CurrentHP + AcidDamagePerHit / AcidHP;
		Params.bIsAlreadyActive = bActivated;
		Params.HitLocation = AcidHit.ImpactLocation;
		USummitTopDownBrazierEventHandler::Trigger_OnHitByAcid(this, Params);

		if(bCompleted)
			return;

		if(bActivated)
			return;

		CurrentHP = CurrentHP + AcidDamagePerHit;

		if (CurrentHP >= AcidHP) 
		{
			bActivated = true;
			StartAnimation();
			SetActorTickEnabled(true);
		}

		if (Parent != nullptr)
			Parent.CheckChildren();
	}

	// UFUNCTION()
	// private void OnHitByRoll(FRollParams Params)
	// {

	// 	if (bAcidResponse)
	// 		return;
		
	// 	if(bCompleted)
	// 		return;

	// 	bActivated = true;
	// 	StartAnimation();
	// 	SetActorTickEnabled(true);

	// 	if (Parent != nullptr)
	// 		Parent.CheckChildren();
	// }

	
	UFUNCTION()
	void OnFinished()
	{
		if(MoveAnimation.IsReversed())
			{
				USummitTopDownBrazierEventHandler::Trigger_OnWingsFinishedMovingBack(this);
				StatueIsInactive.Broadcast();
			}
			
		else
			{
				USummitTopDownBrazierEventHandler::Trigger_OnWingsFinishedMovingOut(this);
				StatueIsActive.Broadcast();
			}
		bFinishedAnimation = !MoveAnimation.IsReversed();
	}

	UFUNCTION()
	void ForceDeactivateBrazier()
	{
		ReverseAnimation();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnFinished()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivated()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnDeactivated()
	{
		
	}

}