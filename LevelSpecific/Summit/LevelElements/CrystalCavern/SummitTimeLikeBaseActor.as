event void FSummitTimeLikeBaseActorSignature();

class ASummitTimeLikeBaseActor : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovableComp;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 1.0;

	UPROPERTY(EditAnywhere)
	bool bAutoReverse;
		
	UPROPERTY(EditAnywhere)
	float DelayDuration = 4;
	
	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere)
	bool bActivateWithAcid;
	
	UPROPERTY(EditAnywhere)
	bool bActivateWithTail;

	UPROPERTY(EditAnywhere)
	bool bDisableDefaultCollision;
	
	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ASummitTimeLikeBaseActor> Children;
	int ChildCount;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bBobWhenActivated;

	UPROPERTY(EditAnywhere, Category = "Setup")
	float BobHeight = 50.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	float BobSpeed = 2.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	float BobOffset = 0.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bIsRotating;
	
	UPROPERTY(EditAnywhere, Category = "Setup")
	FRotator RotationSpeed = FRotator(0,0,0);
	UPROPERTY(EditAnywhere, Category = "Setup")
	FRotator ReverseRotationSpeed = FRotator(0,0,0);
	
	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedGameTime;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedBobbingRotation;

	UPROPERTY()
	FHazeTimeLike MoveAnimation;
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;

	UPROPERTY(DefaultComponent, Attach = MovableComp)
	UStaticMeshComponent RuneMesh1;
	UPROPERTY(DefaultComponent, Attach = RuneMesh1)
	UTeenDragonTailAttackResponseComponent TailResponseComp;
	default TailResponseComp.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent, Attach = MovableComp)
	UStaticMeshComponent RuneMesh2;
	UPROPERTY(DefaultComponent, Attach = RuneMesh2)
	UTeenDragonTailAttackResponseComponent TailResponseComp2;
	default TailResponseComp2.bIsPrimitiveParentExclusive = true;

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	FTransform TransformWhenHit;

	UPROPERTY()
	FSummitTimeLikeBaseActorSignature OnActivated;

	UPROPERTY()
	FSummitTimeLikeBaseActorSignature OnReachedDestination;
	
	UPROPERTY()
	FSummitTimeLikeBaseActorSignature OnHit;

	UPROPERTY()
	FSummitTimeLikeBaseActorSignature OnReset;

	UPROPERTY()
	bool bIsPlaying;
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

		if (DelayDuration == 0)
			DelayDuration = SMALL_NUMBER;

		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		TailResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		TailResponseComp2.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");

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

		if (!bBobWhenActivated)
			return;

		if(!bIsPlaying)
			return;

		if(HasControl())
			SyncedGameTime.Value = Time::GameTimeSeconds;

		MovableComp.SetRelativeLocation(FVector::UpVector * Math::Sin((SyncedGameTime.Value * BobSpeed + BobOffset)) * BobHeight);
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Param)
	{
        if (!bActivateWithAcid)
            return;

        Start();
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if (!bActivateWithTail)
        	return;
		
		if (bIsRotating)
		{
			if(!bIsPlaying)
				Start();
			else
				Reverse();
			return;
		}

		Game::GetPlayer(EHazePlayer::Mio).PlayCameraShake(CameraShake, this, 1.0);
		Game::GetPlayer(EHazePlayer::Zoe).PlayCameraShake(CameraShake, this, 1.0);

		if (bIsPlaying)
			Reverse();
		else
			Start();

		USummitTimeLikeBaseActorEventHandler::Trigger_OnRotationStart(this);

		OnHit.Broadcast();
	}

	UFUNCTION()
	void Start()
	{
		if (bIsDisabled)
			return;

		TransformWhenHit = MovableComp.WorldTransform;
		MoveAnimation.PlayFromStart();

		OnActivated.Broadcast();
		BP_OnActivated();
		bIsPlaying = true;

		if (ChildCount != 0) 
		{
			for (auto Child : Children)
			{
				Child.Start();
			}
		}
	}

	UFUNCTION()
	void Reverse()
	{
		if (bIsDisabled)
			return;

		TransformWhenHit = MovableComp.WorldTransform;
		MoveAnimation.PlayFromStart();

		bIsPlaying = false;
		BP_OnReverse();
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		if (bIsDisabled)
			return;

		if (bIsRotating)
		{
			if (bIsPlaying)
				AddActorLocalRotation(RotationSpeed);
			else
				AddActorLocalRotation(ReverseRotationSpeed);

			return;
		}
		
		if(bIsPlaying)
			MovableComp.SetWorldLocationAndRotation(Math::Lerp(TransformWhenHit.Location, EndingPosition, Alpha), FQuat::SlerpFullPath(TransformWhenHit.Rotation, EndingRotation, Alpha));
		else
			MovableComp.SetWorldLocationAndRotation(Math::Lerp(TransformWhenHit.Location, StartingPosition, Alpha), FQuat::SlerpFullPath(TransformWhenHit.Rotation, StartingRotation, Alpha));
	}

	UFUNCTION()
	void OnFinished()
	{
		if (!bIsPlaying)
		{
			OnReset.Broadcast();
			BP_OnReset();
		}

		OnReachedDestination.Broadcast();
		BP_OnRecachedDestination();
		
		if (CameraShake == nullptr)
			return;
		
		Game::GetPlayer(EHazePlayer::Mio).PlayWorldCameraShake(CameraShake, this, ActorLocation, 2000, 5000);
		Game::GetPlayer(EHazePlayer::Zoe).PlayWorldCameraShake(CameraShake, this, ActorLocation, 2000, 5000);
		USummitTimeLikeBaseActorEventHandler::Trigger_OnRotationStop(this);
	}

	UFUNCTION()
	void DisableMovement() {
		bIsDisabled = true;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivated(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnRecachedDestination(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnReverse(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnReset(){}

}
