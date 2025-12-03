struct FDarkParasiteTargetData
{
	UPROPERTY(BlueprintReadOnly)
	USceneComponent TargetComponent = nullptr;
	UPROPERTY(BlueprintReadOnly)
	FVector RelativeLocation = FVector::ZeroVector;
	UPROPERTY(BlueprintReadOnly)
	bool bIsTargetable = false;
	UPROPERTY(BlueprintReadOnly)
	float Timestamp = -1.0;

	FDarkParasiteTargetData(USceneComponent InTargetComponent,
		FVector InWorldLocation = FVector::ZeroVector)
	{
		TargetComponent = InTargetComponent;
		RelativeLocation = InWorldLocation;
		Timestamp = Time::GameTimeSeconds;

		if (TargetComponent != nullptr)
		{
			bIsTargetable = TargetComponent.IsA(UTargetableComponent);

			RelativeLocation = TargetComponent
				.WorldTransform
				.InverseTransformPosition(InWorldLocation);
		}
	}

	FVector GetWorldLocation() const property
	{
		if (TargetComponent == nullptr)
			return RelativeLocation;

		if (bIsTargetable)
			return TargetComponent.WorldLocation;

		return TargetComponent
			.WorldTransform
			.TransformPosition(RelativeLocation);
	}

	AActor GetActor() const property
	{
		if (TargetComponent == nullptr)
			return nullptr;

		return TargetComponent.Owner;
	}

	bool IsValid() const
	{
		if (TargetComponent == nullptr)
			return false;
		if (TargetComponent.IsBeingDestroyed())
			return false;
		if (TargetComponent.Owner != nullptr && // BSP
			TargetComponent.Owner.IsActorBeingDestroyed())
			return false;

		return true;
	}
}

struct FDarkParasiteGrabData
{
	UPROPERTY(BlueprintReadOnly)
	FDarkParasiteTargetData AttachedData;
	UPROPERTY(BlueprintReadOnly)
	FDarkParasiteTargetData GrabbedData;

	FDarkParasiteGrabData(FDarkParasiteTargetData InAttachedData,
		FDarkParasiteTargetData InGrabbedData)
	{
		AttachedData = InAttachedData;
		GrabbedData = InGrabbedData;
	}
}