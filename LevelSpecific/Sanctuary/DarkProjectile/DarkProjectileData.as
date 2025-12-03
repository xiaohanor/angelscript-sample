struct FDarkProjectileTargetData
{
	UPROPERTY(BlueprintReadOnly)
	USceneComponent Component = nullptr;
	UPROPERTY(BlueprintReadOnly)
	FVector RelativeLocation = FVector::ZeroVector;
	UPROPERTY(BlueprintReadOnly)
	FName SocketName = NAME_None;
	
	FDarkProjectileTargetData(USceneComponent InComponent,
		const FVector& InWorldLocation = FVector::ZeroVector,
		const FName& InSocketName = NAME_None)
	{
		Component = InComponent;
		RelativeLocation = InWorldLocation;
		SocketName = InSocketName;

		if (Component != nullptr)
		{
			RelativeLocation = Component
				.GetSocketTransform(SocketName)
				.InverseTransformPosition(InWorldLocation);
		}
	}

	FVector GetWorldLocation() const property
	{
		if (Component != nullptr)
		{
			return Component
				.GetSocketTransform(SocketName)
				.TransformPosition(RelativeLocation);
		}

		return RelativeLocation;
	}

	bool IsValid() const
	{
		if (Component == nullptr)
			return false;
		if (Component.IsBeingDestroyed())
			return false;
		if (Component.Owner == nullptr)
			return false;
		if (Component.Owner.IsActorBeingDestroyed())
			return false;
		return true;
	}
}

struct FDarkProjectileHitData
{
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Instigator = nullptr;
	UPROPERTY(BlueprintReadOnly)
	FVector Location = FVector::ZeroVector;
	UPROPERTY(BlueprintReadOnly)
	FVector Normal = FVector::ZeroVector;
	UPROPERTY(BlueprintReadOnly)
	FVector Velocity = FVector::ZeroVector;
}

struct FDarkProjectileLaunchData
{
	UPROPERTY()
	FVector Velocity = FVector::ZeroVector;

	FDarkProjectileLaunchData(FVector InVelocity)
	{
		Velocity = InVelocity;
	}
}