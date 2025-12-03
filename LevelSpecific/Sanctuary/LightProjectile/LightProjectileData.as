struct FLightProjectileTargetData
{
	UPROPERTY(BlueprintReadOnly)
	USceneComponent Component = nullptr;
	UPROPERTY(BlueprintReadOnly)
	FVector RelativeLocation = FVector::ZeroVector;
	UPROPERTY(BlueprintReadOnly)
	FName SocketName = NAME_None;
	
	FLightProjectileTargetData(USceneComponent InComponent,
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
}

struct FLightProjectileHitData
{
	UPROPERTY()
	AHazePlayerCharacter Instigator = nullptr;
	
	UPROPERTY()
	FVector Location = FVector::ZeroVector;

	UPROPERTY()
	FVector Normal = FVector::ZeroVector;

	UPROPERTY()
	FVector Velocity = FVector::ZeroVector;
}

struct FLightProjectileLaunchData
{
	UPROPERTY()
	FVector Velocity = FVector::ZeroVector;

	FLightProjectileLaunchData(FVector InVelocity)
	{
		Velocity = InVelocity;
	}
}