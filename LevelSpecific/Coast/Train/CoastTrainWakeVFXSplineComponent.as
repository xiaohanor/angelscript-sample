class UCoastTrainWakeVFXSplineComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	UNiagaraSystem Niagara;

	UPROPERTY(EditAnywhere)
	AActor ActorToFollow;

	UPROPERTY(EditAnywhere)
	float SplineDistanceOffset;

	UPROPERTY(EditAnywhere)
	FVector RelativeOffset;

	UPROPERTY(EditAnywhere)
	FVector WorldScale = FVector(1.0);
	
	UHazeSplineComponent Spline;
	UNiagaraComponent NiagaraComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spline = Spline::GetGameplaySpline(Owner);
		NiagaraComponent = UNiagaraComponent::Create(Owner);
		NiagaraComponent.Deactivate();
		NiagaraComponent.Asset = Niagara;
		NiagaraComponent.WorldScale3D = WorldScale;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActivateVFX();
		float SplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(ActorToFollow.ActorLocation);
		SplineDistance += SplineDistanceOffset;
		FTransform RelevantTransform = Spline.GetWorldTransformAtSplineDistance(SplineDistance);
		NiagaraComponent.WorldLocation = RelevantTransform.Location + RelevantTransform.TransformVectorNoScale(RelativeOffset);
		NiagaraComponent.WorldRotation = RelevantTransform.Rotator();
	}

	UFUNCTION()
	void ActivateVFX()
	{
		NiagaraComponent.Activate();
	}

	UFUNCTION()
	void DeactivateVFX()
	{
		NiagaraComponent.Deactivate();
	}
}