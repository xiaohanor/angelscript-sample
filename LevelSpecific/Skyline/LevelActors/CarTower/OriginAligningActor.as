class AOriginAligningActor : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	// Use this actor for alignement, otherwise alignment is to AttachParent
	UPROPERTY(EditAnywhere)
	AActor AlignToActor;

	UPROPERTY(EditAnywhere)
	bool bAlignPitch = false;

	UPROPERTY(EditAnywhere)
	bool bAlignYaw = true;

	UPROPERTY(EditAnywhere)
	float SnapToRadius = 0.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		FVector Origin;

		if (AlignToActor != nullptr)
			Origin = AlignToActor.ActorLocation;
		else if (AttachParentActor != nullptr)
			Origin = AttachParentActor.ActorLocation;
		else
			return;

		FVector ToOrigin = ActorLocation - Origin;

		if (!bAlignPitch)
			ToOrigin = ToOrigin.VectorPlaneProject(FVector::UpVector);

		if (SnapToRadius > 0.0)
		{
			FVector Location = Origin + ToOrigin.SafeNormal * SnapToRadius;
			SetActorLocation(FVector(Location.X, Location.Y, ActorLocation.Z));
		}

//		SetActorRotation(ToOrigin.Rotation());
		SetActorRotation(FRotator::MakeFromXZ(ToOrigin.SafeNormal, ActorUpVector));
	}
}