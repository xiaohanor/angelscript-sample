class UDarkMassMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(DarkMass::Tags::DarkMass);
	default CapabilityTags.Add(DarkMass::Tags::DarkMassMovement);

	default DebugCategory = DarkMass::Tags::DarkMass;

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 53;

	UDarkMassUserComponent UserComp;
	FVector Velocity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UDarkMassUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (UserComp.MassActor == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (UserComp.MassActor == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Velocity = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const auto& SurfaceData = UserComp.MassActor.CurrentSurface;
		const FVector ToTarget = (SurfaceData.WorldLocation - UserComp.MassActor.ActorLocation);

		if (SurfaceData.IsValid())
		{
			if (!DarkMass::bHoldToMove || IsActioning(ActionNames::PrimaryLevelAbility))
				Velocity += ToTarget.GetSafeNormal() * DarkMass::AccelerationSpeed * DeltaTime;
		}

		Velocity -= Velocity * DarkMass::Drag * DeltaTime;

		if (Velocity.SizeSquared() > Math::Square(DarkMass::MaximumSpeed))
			Velocity = Velocity.GetSafeNormal() * DarkMass::MaximumSpeed;

		const FVector DeltaMovement = Velocity * DeltaTime;
		if (!DeltaMovement.IsNearlyZero())
		{
			UserComp.MassActor.SetActorLocationAndRotation(
				UserComp.MassActor.ActorLocation + DeltaMovement,
				FRotator::MakeFromX(DeltaMovement.GetSafeNormal())
			);
		}
	}
}