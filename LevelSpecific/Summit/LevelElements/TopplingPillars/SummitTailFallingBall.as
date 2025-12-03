event void FASummitTailFallingBallSignature();
event void FOnSummitBallFinished();

class ASummitTailFallingBall : AHazeActor
{
	UPROPERTY()
	FOnSummitBallFinished OnSummitBallFinished;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent DestinationComp;
	
	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent SplineStartComp;
	
	UPROPERTY()
	UNiagaraSystem Effect;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;
	UHazeSplineComponent Spline;
	float DistanceAlongSpline;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger TriggerRef;
	
	UPROPERTY()
	FVector DestinationUpVector = FVector::UpVector;

	bool bIsActivated;

	/* TIMING SETTINGS */
	float FallDuration = 1.1;
	float MoveDuration = 7.0;
	float DelayDuration = 0.1;

	float RotationSpeed = 5;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike FallAnimation;	
	default FallAnimation.Duration = FallDuration;
	default FallAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = MoveDuration;
	default MoveAnimation.UseSmoothCurveZeroToOne();
	
	FHazeTimeLike  DelayAnimation;
	default DelayAnimation.Duration = DelayDuration;
	default DelayAnimation.UseSmoothCurveZeroToOne();
	
	FRuntimeFloatCurve Speed;
	default Speed.AddDefaultKey(0.0, 0.0);
	default Speed.AddDefaultKey(1.0, 1.0);

	FRuntimeFloatCurve Rotation;
	default Rotation.AddDefaultKey(0.0, 0.0);
	default Rotation.AddDefaultKey(1.0, 1.0);

	FTransform StartingTransform;
	FRotator StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FRotator EndingRotation;
	FVector EndingPosition;

	bool bGoingForward;
	bool bMioOn;
	bool bZoeOn;
	
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(SplineActor != nullptr)
		{
			Spline = SplineActor.Spline;
			// OnUpdate(0.0);

			SplineStartComp.SetWorldLocation(Spline.GetWorldTransformAtSplineDistance(0).GetLocation());
			DestinationComp.SetWorldLocation(Spline.GetWorldTransformAtSplineDistance(Spline.SplineLength).GetLocation());
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(SplineActor == nullptr)
			return;
		Spline = SplineActor.Spline;

		StartingTransform = Spline.GetWorldTransformAtSplineDistance(0);
		StartingPosition = Root.GetWorldLocation();
		EndingTransform =  Spline.GetWorldTransformAtSplineDistance(0);
		EndingPosition = EndingTransform.GetLocation();

		StartingRotation = GetActorRelativeRotation();
		EndingRotation = DestinationComp.GetWorldRotation();

		FallAnimation.BindUpdate(this, n"OnFallUpdate");
		FallAnimation.BindFinished(this, n"OnFallFinished");

		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		DelayAnimation.BindFinished(this, n"OnDelayFinished");

		if(TriggerRef != nullptr)
			TriggerRef.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bIsActivated)
			return;

		
	}

	UFUNCTION()
	void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if (MoveAnimation.IsPlaying())
			return;


		if (Player == Game::GetPlayer(EHazePlayer::Mio)) 
			return;
		
		Activate();
		TriggerRef.OnPlayerEnter.Unbind(this, n"OnPlayerEnter"); //DB change: unbound to prevent retriggering ball animation
	}

	UFUNCTION()
	private void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{	

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player == Game::GetPlayer(EHazePlayer::Mio)) 
			bMioOn = false;

		if (Player == Game::GetPlayer(EHazePlayer::Zoe)) 
			bZoeOn = false;

	}

	UFUNCTION()
	void OnFallUpdate(float Alpha)
	{
		SetActorLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		AddActorLocalRotation(FRotator(-(RotationSpeed / 2),-(RotationSpeed / 2),-(RotationSpeed / 2)));
		// SetActorLocationAndRotation(Math::Lerp(StartingPosition, EndingPosition, Alpha), FQuat::SlerpFullPath(FQuat(0,0,0), FQuat(0,180,0), Alpha));
	}

	UFUNCTION()
	void OnFallFinished()
	{
		Print("OnFallFinished", 15);
		MoveAnimation.PlayFromStart();
	}
	
	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		DistanceAlongSpline = Spline.SplineLength * Speed.GetFloatValue(Alpha);

		FTransform TransformAtDistance = Spline.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
		FVector CurrentLocation = TransformAtDistance.Location;
		// FQuat CurrentRotation = FQuat::Slerp(TransformAtDistance.Rotation, FQuat::MakeFromZX(DestinationUpVector, TransformAtDistance.Rotation.ForwardVector), Rotation.GetFloatValue(Alpha));
		
		SetActorLocation(CurrentLocation);

		AddActorLocalRotation(FRotator(-RotationSpeed,RotationSpeed,-RotationSpeed));

	}

	UFUNCTION()
	void OnFinished()
	{
		AddActorDisable(this);
		OnSummitBallFinished.Broadcast();
		// BP_OnCompleted();
	}

	
	UFUNCTION()
	void OnDelayFinished()
	{
	}

	UFUNCTION()
	void Activate()
	{
		bIsActivated = true;
		if (!FallAnimation.IsPlaying() || !MoveAnimation.IsPlaying() )
			FallAnimation.PlayFromStart();
	}

	UFUNCTION()
	void Deactivate()
	{
		bIsActivated = false;
		MoveAnimation.Stop();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnCompleted() {}

}