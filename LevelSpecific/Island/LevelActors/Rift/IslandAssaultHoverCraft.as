event void FIslandAssaultHoverCraftSignature();

class AIslandAssaultHoverCraft : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestructionPosition;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RespawnPositionComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MovableObject;

	UPROPERTY(DefaultComponent, Attach=MovableObject)
	USceneComponent BobbingRoot;

	UPROPERTY(DefaultComponent, Attach=ConeRotate)
	USceneComponent AIAttachPoint;

	UPROPERTY(DefaultComponent, Attach=ConeRotate)
	USceneComponent AIAttachPointTwo;

	UPROPERTY(DefaultComponent, Attach=ConeRotate)
	USceneComponent AIAttachPointThree;

	UPROPERTY(DefaultComponent, Attach=ConeRotate)
	USceneComponent AIAttachPointFour;

	UPROPERTY(DefaultComponent, Attach = BobbingRoot)
	UFauxPhysicsConeRotateComponent ConeRotate;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedGameTime;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedBobbingRotation;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(EditAnywhere)
	EIslandRedBlueWeaponType Color;
	
	UPROPERTY(EditAnywhere)
	float BobHeight = 50.0;

	UPROPERTY(EditAnywhere)
	float BobSpeed = 2.0;

	UPROPERTY(EditAnywhere)
	float BobOffset = 0.0;

	UPROPERTY(EditAnywhere)
	bool bDisableBobbing = false;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;
	UHazeSplineComponent Spline;

	UPROPERTY(BlueprintReadOnly)
	float DistanceAlongSpline;
	
	UPROPERTY(EditAnywhere)
	float TravelDuration = 1.0;

	UPROPERTY(EditAnywhere)
	FVector DestinationUpVector = FVector::UpVector;

	UPROPERTY()
	FIslandAssaultHoverCraftSignature OnReachedDestination;

	UPROPERTY()
	FIslandAssaultHoverCraftSignature OnSplineReachedDestination;

	UPROPERTY()
	FIslandAssaultHoverCraftSignature OnRespawnComplete;

	UPROPERTY()
	FHazeTimeLike SplineMoveAnimation;	
	default SplineMoveAnimation.Duration = 8.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FRuntimeFloatCurve Speed;
	default Speed.AddDefaultKey(0.0, 0.0);
	default Speed.AddDefaultKey(1.0, 1.0);

	FRuntimeFloatCurve Rotation;
	default Rotation.AddDefaultKey(1.0, 0.0);
	// default Rotation.AddDefaultKey(10.0, 1.0);

	UPROPERTY()
	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 5.0;
	default MoveAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default MoveAnimation.Curve.AddDefaultKey(5.0, 1.0);

	FTransform StartingTransform;
	FTransform EndingTransform;
	FVector StartingPosition;
	FQuat StartingRotation;
	FVector EndingPosition;
	FQuat EndingRotation;
	FTransform CurrentTransform;
	FVector CurrentPosition;
	FQuat CurrentRotation;

	UPROPERTY()
	FHazeTimeLike RespawnMoveAnimation;	
	default RespawnMoveAnimation.Duration = 10.0;
	default RespawnMoveAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default RespawnMoveAnimation.Curve.AddDefaultKey(10.0, 1.0);

	FTransform RespawnTransform;
	FVector RespawnPosition;
	FQuat RespawnRotation;

	UPROPERTY()
	bool bIsDestroyed;

	UPROPERTY(EditAnywhere)
	bool bSmoothDestruction;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(SplineActor != nullptr)
		{
			Spline = SplineActor.Spline;
			OnSplineUpdate(0.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (SplineActor != nullptr)
		{
			Spline = SplineActor.Spline;
			OnSplineUpdate(0.0);
		}
		EndingTransform = DestructionPosition.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		StartingTransform = MovableObject.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		RespawnTransform = RespawnPositionComp.GetWorldTransform();
		RespawnPosition = RespawnTransform.GetLocation();
		RespawnRotation = RespawnTransform.GetRotation();

		SplineMoveAnimation.BindUpdate(this, n"OnSplineUpdate");
		SplineMoveAnimation.BindFinished(this, n"OnSplineFinished");
		SplineMoveAnimation.SetPlayRate(1.0 / TravelDuration);

		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");
		MoveAnimation.SetPlayRate(1.0 / TravelDuration);

		RespawnMoveAnimation.BindUpdate(this, n"OnRespawnUpdate");
		RespawnMoveAnimation.BindFinished(this, n"OnRespawnFinished");
		RespawnMoveAnimation.SetPlayRate(1.0 / TravelDuration);

		// BobOffset = (BobOffset * 3 + 1) / 2;

		if(HasControl())
		{
			SyncedGameTime.Value = Time::GameTimeSeconds;
			SyncedBobbingRotation.Value = BobbingRoot.RelativeRotation;
		}

		AddActorTickBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HasControl())
			SyncedGameTime.Value = Time::GameTimeSeconds;

		if (bDisableBobbing)
			return;

		if (!bIsDestroyed)
			BobbingRoot.SetRelativeLocation(FVector::UpVector * Math::Sin((SyncedGameTime.Value * BobSpeed + BobOffset)) * BobHeight);
		
		if (bIsDestroyed && bSmoothDestruction == false)
		{

			if(HasControl())
			{
				FRotator BobbingRotation = Math::RInterpConstantTo(BobbingRoot.RelativeRotation, FRotator(Math::Sin((SyncedGameTime.Value * 10 + BobOffset)), Math::Sin((SyncedGameTime.Value * 10 + BobOffset)), 0), DeltaSeconds, 15);
				SyncedBobbingRotation.Value = BobbingRotation;
			}

			BobbingRoot.SetRelativeRotation(SyncedBobbingRotation.Value);
		}
	}

	UFUNCTION()
	void OnSplineUpdate(float Alpha)
	{

		DistanceAlongSpline = Spline.SplineLength * Speed.GetFloatValue(Alpha);

		FTransform TransformAtDistance = Spline.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
		FVector CurrentLocation = TransformAtDistance.Location;
		// FQuat CurrentRotationz = FQuat::Slerp(TransformAtDistance.Rotation, FQuat::MakeFromZX(DestinationUpVector, TransformAtDistance.Rotation.ForwardVector), Rotation.GetFloatValue(Alpha));

		if (Alpha > 0.93)
			OnSplineReachedDestination.Broadcast();

		if (Alpha < 0.99)
			SetActorLocation(CurrentLocation);
			// SetActorLocationAndRotation(CurrentLocation, CurrentRotationz);
			
			
	}

	UFUNCTION()
	void OnSplineFinished()
	{
		OnSplineReachedDestination.Broadcast();
	}

	UFUNCTION()
	void ActivateSplineMove()
	{
		SplineMoveAnimation.PlayFromStart();
		RemoveActorTickBlock(this);
	}

	UFUNCTION()
	void DeactivateSplineMove()
	{
		SplineMoveAnimation.Stop();
	}

	
	UFUNCTION()
	void Activate()
	{
		SplineMoveAnimation.Stop();
		RespawnMoveAnimation.Stop();
		CurrentTransform = MovableObject.GetWorldTransform();
		CurrentPosition = CurrentTransform.GetLocation();
		CurrentRotation = CurrentTransform.GetRotation();

		MoveAnimation.PlayFromStart();
		RemoveActorTickBlock(this);
	}

	UFUNCTION()
	void Deactivate()
	{
		MoveAnimation.Stop();
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{

		MovableObject.SetWorldLocation(Math::Lerp(CurrentPosition, EndingPosition, Alpha));
		MovableObject.SetWorldRotation(FQuat::Slerp(CurrentRotation, EndingRotation, Alpha / 1.5));

		if (Alpha > 0.8)
			ExplodeActor();

	}

	UFUNCTION()
	void OnFinished()
	{
		OnReachedDestination.Broadcast();
	}

	UFUNCTION()
	void OnRespawnUpdate(float Alpha)
	{

		MovableObject.SetWorldLocation(Math::Lerp(RespawnPosition, StartingPosition, Alpha));
		MovableObject.SetWorldRotation(FQuat::Slerp(RespawnRotation, StartingRotation, Alpha));

	}

	UFUNCTION()
	void OnRespawnFinished()
	{
		
	}

	
	UFUNCTION()
	void Respawn()
	{
		if(Spline != nullptr)
		{
			MovableObject.SetRelativeLocation(FVector(0,0,0));
			MovableObject.SetRelativeRotation(FRotator(0,0,0));
			SetActorLocation(StartingPosition);
			SetActorRotation(StartingRotation);

			// SetActorLocationAndRotation(StartingPosition, StartingRotation);
			OnSplineUpdate(0.0);
			SplineMoveAnimation.PlayFromStart();
		}
		else
		{
			MovableObject.SetWorldLocation(RespawnPosition);
			MovableObject.SetWorldRotation(RespawnRotation);
			SetActorLocationAndRotation(RespawnPosition, RespawnRotation);
			RespawnMoveAnimation.PlayFromStart();
		}

		// MovableObject.SetWorldLocation(Fvector RespawnPosition, RespawnRotation);
		// MovableObject.SetWorldLocation(RespawnPosition, RespawnRotation);
		BP_Respawn();
		OnRespawnComplete.Broadcast();

		if (Color == EIslandRedBlueWeaponType::Blue) {
			Color = EIslandRedBlueWeaponType::Red;
			UpdateColors();
			return;
		} 
		
		if (Color == EIslandRedBlueWeaponType::Red) {
			Color = EIslandRedBlueWeaponType::Blue;
			UpdateColors();
			return;
		}
			 
	}

	UFUNCTION()
	void ExplodeActor()
	{
		BP_ExplodeActor();
	}

	UFUNCTION()
	void UpdateColors()
	{
		BP_UpdateColors();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ExplodeActor(){}

	UFUNCTION(BlueprintEvent)
	void BP_Respawn(){}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateColors(){}

}