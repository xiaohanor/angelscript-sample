struct FDarkMassSurfaceData
{
	UPROPERTY(BlueprintReadOnly)
	UPrimitiveComponent SurfaceComponent = nullptr;
	UPROPERTY(BlueprintReadOnly)
	FName SocketName = NAME_None;
	UPROPERTY(BlueprintReadOnly)
	FVector RelativeLocation = FVector::ZeroVector;
	UPROPERTY(BlueprintReadOnly)
	FVector RelativeNormal = FVector::ForwardVector;

	FDarkMassSurfaceData(UPrimitiveComponent InSurfaceComponent,
		FName InSocketName = NAME_None,
		FVector InWorldLocation = FVector::ZeroVector,
		FVector InWorldNormal = FVector::ForwardVector)
	{
		SurfaceComponent = InSurfaceComponent;
		SocketName = InSocketName;
		RelativeLocation = InWorldLocation;
		RelativeNormal = InWorldNormal;

		if (SurfaceComponent != nullptr)
		{
			RelativeLocation = SurfaceComponent
				.GetSocketTransform(SocketName)
				.InverseTransformPosition(InWorldLocation);

			RelativeNormal = SurfaceComponent
				.GetSocketTransform(SocketName)
				.InverseTransformVector(InWorldNormal);
		}
	}

	FVector GetWorldLocation() const property
	{
		if (SurfaceComponent != nullptr)
		{
			return SurfaceComponent
				.GetSocketTransform(SocketName)
				.TransformPosition(RelativeLocation);
		}

		return RelativeLocation;
	}

	FVector GetWorldNormal() const property
	{
		if (SurfaceComponent != nullptr)
		{
			return SurfaceComponent
				.GetSocketTransform(SocketName)
				.TransformVector(RelativeNormal);
		}

		return RelativeNormal;
	}

	AActor GetActor() const property
	{
		if (SurfaceComponent == nullptr)
			return nullptr;

		return SurfaceComponent.Owner;
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

		return true;
	}
}

struct FDarkMassGrabData
{
	UPROPERTY(BlueprintReadOnly)
	UTargetableComponent Component = nullptr;

	FDarkMassGrabData(UTargetableComponent InComponent)
	{
		Component = InComponent;
	}
}