class USkylineSentryBossSphericalMovementComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	bool bAllowZMovement = false;

	UPROPERTY(EditAnywhere)
	USceneComponent Origin;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetOrigin();
	}

	void SetOrigin(USceneComponent NewOrigin = nullptr)
	{
		if (NewOrigin != nullptr)	
			Origin = NewOrigin;
		else if (Owner.AttachParentActor != nullptr)
			Origin = Owner.AttachParentActor.RootComponent;		
	}

	FTransform GetTransformFromDelta(FVector Delta)
	{
		FTransform Transform;

		FVector OriginToOwner = Owner.ActorLocation - Origin.WorldLocation;

		float Radius = OriginToOwner.Size();

//		Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + Delta.SafeNormal * 500.0, FLinearColor::Red, 10.0, 0.0);

		FVector RotationAxis;
		RotationAxis = OriginToOwner.SafeNormal.CrossProduct(Delta) / Radius;

		Transform.Location = Origin.WorldLocation + OriginToOwner.RotateAngleAxis(Math::RadiansToDegrees(RotationAxis.Size()), RotationAxis.SafeNormal);

		if (bAllowZMovement)
			Transform.Location = Transform.Location + Delta.ProjectOnTo(UpVector);

		Transform.Rotation = FQuat::MakeFromZX(OriginToOwner.SafeNormal, Delta.SafeNormal);

		return Transform;
	}

	FVector GetUpVector() property
	{
		return (Owner.ActorLocation - Origin.WorldLocation).SafeNormal;
	}
}