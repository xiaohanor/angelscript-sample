event void FIslandEntranceFallingShipSignature();

class AIslandEntranceFallingShip : AHazeActor
{
	UPROPERTY(EditDefaultsOnly)
	int HitEffectTranslucencySortPriority = 100;	

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem HitEffect;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;
	UHazeSplineComponent Spline;
	float DistanceAlongSpline;

	UFUNCTION(BlueprintPure)
	float GetSplineAlpha()
	{
		return DistanceAlongSpline/Spline.SplineLength;
	}
	
	UPROPERTY(EditAnywhere)
	float TravelDuration = 1.0;

	UPROPERTY(EditAnywhere)
	FVector DestinationUpVector = FVector::UpVector;

	UPROPERTY(EditAnywhere)
	FRotator EndRotation = FRotator(45,110,2000);

	UPROPERTY()
	FIslandEntranceFallingShipSignature OnReachedDestination;

	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default MoveAnimation.Curve.AddDefaultKey(1.0, 1.0);
	// default MoveAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Speed;
	default Speed.AddDefaultKey(0.0, 0.0);
	default Speed.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Rotation;
	default Rotation.AddDefaultKey(0.0, 0.0);
	default Rotation.AddDefaultKey(1.0, 1.0);

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(SplineActor != nullptr)
		{
			Spline = SplineActor.Spline;
			OnUpdate(1.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spline = SplineActor.Spline;
		OnUpdate(0.0);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");
		MoveAnimation.SetPlayRate(1.0 / TravelDuration);

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// if(MoveAnimation.IsPlaying())
			
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		DistanceAlongSpline = Spline.SplineLength * Speed.GetFloatValue(Alpha);

		FTransform TransformAtDistance = Spline.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
		FVector CurrentLocation = TransformAtDistance.Location;
		FQuat CurrentRotation = FQuat::Slerp(TransformAtDistance.Rotation, FQuat::MakeFromZX(DestinationUpVector, TransformAtDistance.Rotation.ForwardVector), Rotation.GetFloatValue(Alpha));
		SetActorRotation(Math::RInterpTo(FRotator(0,0,0), EndRotation, Alpha, 1));
		
		// SetActorLocationAndRotation(CurrentLocation, CurrentRotation);
		SetActorLocation(CurrentLocation);
	}

	UFUNCTION()
	void OnFinished()
	{
		OnReachedDestination.Broadcast();
		UNiagaraComponent Explosion = Niagara::SpawnOneShotNiagaraSystemAtLocation(HitEffect, ActorLocation, ActorRotation, FVector(15,15,15));
		Explosion.SetTranslucentSortPriority(HitEffectTranslucencySortPriority);
		UIslandEntranceFallingShipEventHandler::Trigger_Exploded(this);
	}

	UFUNCTION()
	void Activate()
	{
		MoveAnimation.Play();
		UIslandEntranceFallingShipEventHandler::Trigger_StartFalling(this);
	}

	UFUNCTION()
	void Deactivate()
	{
		MoveAnimation.Stop();
	}

};

UCLASS(Abstract)
class UIslandEntranceFallingShipEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartFalling() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Exploded() {};

};