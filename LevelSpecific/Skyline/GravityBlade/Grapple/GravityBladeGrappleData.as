struct FGravityBladeGrappleData
{
	UPROPERTY(BlueprintReadOnly)
	UGravityBladeGrappleComponent GrappleComponent = nullptr;
	UPROPERTY(BlueprintReadOnly)
	UGravityBladeGrappleResponseComponent ResponseComponent = nullptr;
	UPROPERTY(BlueprintReadOnly)
	UGravityBladeGravityShiftComponent ShiftComponent = nullptr;
	UPROPERTY(BlueprintReadOnly)
	FVector RelativeLocation = FVector::ZeroVector;
	UPROPERTY(BlueprintReadOnly)
	FQuat RelativeRotation = FQuat::Identity;
	UPROPERTY(BlueprintReadOnly)
	bool bIsCombatGrapple = false;

	bool bAlwaysAirGrapple = false;

	FGravityBladeGrappleData(UGravityBladeGrappleComponent InGrappleComponent,
		FVector InWorldLocation = FVector::ZeroVector,
		FQuat InWorldRotation = FQuat::Identity,
		UGravityBladeGrappleResponseComponent InResponseComponent = nullptr,
		UGravityBladeGravityShiftComponent InShiftComponent = nullptr)
	{
		GrappleComponent = InGrappleComponent;
		RelativeLocation = InWorldLocation;
		RelativeRotation = InWorldRotation;
		ResponseComponent = InResponseComponent;
		ShiftComponent = InShiftComponent;

		if (GrappleComponent != nullptr)
		{
			RelativeLocation = GrappleComponent.WorldTransform.InverseTransformPosition(InWorldLocation);
			RelativeRotation = GrappleComponent.WorldTransform.InverseTransformRotation(InWorldRotation);
		}
	}

	FVector GetWorldLocation() const property
	{
		if (GrappleComponent != nullptr)
			return GrappleComponent.WorldTransform.TransformPosition(RelativeLocation);

		return RelativeLocation;
	}

	FQuat GetWorldRotation() const property
	{
		if (GrappleComponent != nullptr)
			return GrappleComponent.WorldTransform.TransformRotation(RelativeRotation);

		return RelativeRotation;
	}

	FTransform GetWorldTransform() const property
	{
		return FTransform(WorldRotation, WorldLocation);
	}

	FVector GetWorldUp() const property
	{
		if (GrappleComponent != nullptr)
			return GrappleComponent.WorldTransform.TransformRotation(RelativeRotation).UpVector;

		return RelativeRotation.UpVector;
	}

	FVector GetWorldForward() const property
	{
		if (GrappleComponent != nullptr)
			return GrappleComponent.WorldTransform.TransformRotation(RelativeRotation).ForwardVector;

		return RelativeRotation.ForwardVector;
	}

	AActor GetActor() const property
	{
		if (GrappleComponent == nullptr)
			return nullptr;

		return GrappleComponent.Owner;
	}

	bool CanShiftGravity() const
	{
		if (ShiftComponent == nullptr)
			return false;

		if (ShiftComponent.IsBeingDestroyed())
			return false;

		return true;
	}

	bool IsValid() const
	{
		if (GrappleComponent == nullptr)
			return false;

		if (GrappleComponent.IsBeingDestroyed())
			return false;

		if (GrappleComponent.Owner == nullptr)
			return false;

		if (GrappleComponent.Owner.IsActorBeingDestroyed())
			return false;

		if(ShiftComponent != nullptr && ShiftComponent.bEjectPlayer)
			return false;

		return true;
	}
}

struct FGravityBladeGravityAlignSurface
{
	UPROPERTY(BlueprintReadOnly)
	UPrimitiveComponent SurfaceComponent;
	UPROPERTY(BlueprintReadOnly)
	UGravityBladeGravityShiftComponent ShiftComponent;
	UPROPERTY(BlueprintReadOnly)
	FVector SurfaceLocation;
	UPROPERTY(BlueprintReadOnly)
	FVector SurfaceNormal = FVector::UpVector;

	bool WasEjected() const
	{
		if(ShiftComponent == nullptr)
			return false;

		return ShiftComponent.bEjectPlayer;
	}

	bool IsValid() const
	{
		if (SurfaceComponent == nullptr)
			return false;

		if (SurfaceComponent.IsBeingDestroyed())
			return false;

		if (SurfaceComponent.Owner == nullptr)
			return false;

		if (SurfaceComponent.Owner.IsActorBeingDestroyed())
			return false;

		if (ShiftComponent == nullptr)
			return false;

		if (ShiftComponent.IsBeingDestroyed())
			return false;

		if(ShiftComponent.bEjectPlayer)
			return false;

		return true;
	}
}

struct FGravityBladeThrowData
{
	UPROPERTY(BlueprintReadOnly)
	FVector Location;
	UPROPERTY(BlueprintReadOnly)
	FVector Normal;
	UPROPERTY(BlueprintReadOnly)
	float ThrowDuration = 0.0;

	FGravityBladeThrowData(const FVector& InLocation, const FVector& InNormal)
	{
		Location = InLocation;
		Normal = InNormal;
	}
}

struct FGravityBladeGravityTransitionData
{
	UPROPERTY(BlueprintReadOnly)
	bool bTransitionToOriginalGravity = false;

	UPROPERTY(BlueprintReadOnly)
	bool bWillAffectCamera = false;

	UPROPERTY(BlueprintReadOnly)
	float PullDuration = 0.0;
}