event void FASummitEggPathRollingWheelSignature();

class ASummitEggPathRollingWheel : AHazeActor
{

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
	bool bHasActivatedOnce = false;

	/* TIMING SETTINGS */
	float FallDuration = 1.1;
	float MoveDuration = 7.0;
	float DelayDuration = 0.1;

	UPROPERTY(EditAnywhere)
	float RotationSpeed = 80.0;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike FallAnimation;	
	default FallAnimation.Duration = FallDuration;
	default FallAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = MoveDuration;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	bool bShouldFollowSplineRotation = false;
	
	FHazeTimeLike  DelayAnimation;
	default DelayAnimation.Duration = DelayDuration;
	default DelayAnimation.UseSmoothCurveZeroToOne();

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

			StartingTransform = Spline.GetWorldTransformAtSplineDistance(0);
			SplineStartComp.SetWorldLocation(StartingTransform.GetLocation());

			if(bShouldFollowSplineRotation)
			{
				FQuat StartRotation = FQuat::MakeFromYZ(StartingTransform.Rotation.RightVector, SplineStartComp.UpVector);
				SplineStartComp.SetWorldRotation(StartRotation);
			}
			else
			{
				SplineStartComp.SetWorldRotation(ActorRotation);	
			}

			EndingTransform = Spline.GetWorldTransformAtSplineDistance(Spline.SplineLength);
			DestinationComp.SetWorldLocation(EndingTransform.GetLocation());

			if(bShouldFollowSplineRotation)
			{
				FQuat EndRotation = FQuat::MakeFromYZ(EndingTransform.Rotation.RightVector, DestinationComp.UpVector);
				DestinationComp.SetWorldRotation(EndRotation);
			}
			else
			{
				DestinationComp.SetWorldRotation(ActorRotation);
			}
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

	UFUNCTION()
	void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if(bHasActivatedOnce)
			return;

		Activate();
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
	}

	UFUNCTION()
	void OnFallFinished()
	{
		MoveAnimation.PlayFromStart();
	}
	
	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		DistanceAlongSpline = Spline.SplineLength * Alpha;

		FTransform TransformAtDistance = Spline.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
		FVector CurrentLocation = TransformAtDistance.Location;
		SetActorLocation(CurrentLocation);
		
		float DeltaTime = Time::GetActorDeltaSeconds(this);
		AddActorLocalRotation(FRotator(-RotationSpeed * DeltaTime,0,0));
		
		if(bShouldFollowSplineRotation)
		{
			FQuat NewRotation = FQuat::MakeFromYZ(TransformAtDistance.Rotation.RightVector, ActorUpVector);
			SetActorRotation(NewRotation);
		}
	}

	UFUNCTION()
	void OnFinished()
	{


	}

	
	UFUNCTION()
	void OnDelayFinished()
	{
	}

	UFUNCTION()
	void Activate()
	{
		bIsActivated = true;
		bHasActivatedOnce = true;
		if (!FallAnimation.IsPlaying() || !MoveAnimation.IsPlaying() )
			FallAnimation.PlayFromStart();
	}

	UFUNCTION()
	void Deactivate()
	{
		bIsActivated = false;
		MoveAnimation.Stop();
	}

}

UCLASS(Abstract)
class UASummitEggPathRollingWheelEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedDestination() {}
}