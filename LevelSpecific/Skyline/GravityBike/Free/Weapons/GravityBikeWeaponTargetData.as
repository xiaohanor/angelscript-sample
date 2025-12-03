struct FGravityBikeWeaponTargetData
{
	private bool bIsValid = false;
	private bool bIsComponentTarget = false;

	UPROPERTY(BlueprintReadOnly)
	USceneComponent TargetComponent = nullptr;

	UPROPERTY(BlueprintReadOnly)
	FVector RelativeLocation = FVector::ZeroVector;

	UPROPERTY(BlueprintReadOnly)
	FQuat RelativeRotation = FQuat::Identity;

	/**
	 * Construct a target data that targets a component
	 */
	FGravityBikeWeaponTargetData(
		USceneComponent InTargetComponent,
		FVector InWorldLocation,
		FQuat InWorldRotation = FQuat::Identity)
	{
		if(!ensure(InTargetComponent != nullptr))
			return;

		bIsComponentTarget = true;

		TargetComponent = InTargetComponent;

		RelativeLocation = TargetComponent
			.WorldTransform
			.InverseTransformPosition(InWorldLocation);

		RelativeRotation = TargetComponent
			.WorldTransform
			.InverseTransformRotation(InWorldRotation);

		bIsValid = true;
	}

	/**
	 * Construct a target data that targets a world location
	 */
	FGravityBikeWeaponTargetData(
		FVector InWorldLocation,
		FQuat InWorldRotation = FQuat::Identity)
	{
		bIsComponentTarget = false;

		TargetComponent = nullptr;
		RelativeLocation = InWorldLocation;
		RelativeRotation = InWorldRotation;

		bIsValid = true;
	}

	FVector GetWorldLocation() const
	{
		if (TargetComponent != nullptr)
		{
			return TargetComponent
				.WorldTransform
				.TransformPosition(RelativeLocation);
		}

		return RelativeLocation;
	}

	FQuat GetWorldRotation() const
	{
		if (TargetComponent != nullptr)
		{
			return TargetComponent
				.WorldTransform
				.TransformRotation(RelativeRotation);
		}

		return RelativeRotation;
	}

	FTransform GetWorldTransform() const
	{
		return FTransform(GetWorldRotation(), GetWorldLocation());
	}

	FVector GetWorldForward() const
	{
		if (TargetComponent != nullptr)
		{
			return TargetComponent
				.WorldTransform
				.TransformRotation(RelativeRotation)
				.ForwardVector;
		}

		return RelativeRotation.ForwardVector;
	}

	AActor GetActor() const
	{
		if (TargetComponent == nullptr)
			return nullptr;

		return TargetComponent.Owner;
	}

	bool IsHoming() const
	{
		if(!bIsValid)
			return false;

		if(bIsComponentTarget)
		{
			if (TargetComponent == nullptr)
				return false;
			if (TargetComponent.IsBeingDestroyed())
				return false;
			if (TargetComponent.Owner == nullptr)
				return false;
			if (TargetComponent.Owner.IsActorBeingDestroyed())
				return false;

			const auto HealthComp = UBasicAIHealthComponent::Get(TargetComponent.Owner);
			if(HealthComp != nullptr && HealthComp.IsDead())
				return false;
		}

		return true;
	}
};