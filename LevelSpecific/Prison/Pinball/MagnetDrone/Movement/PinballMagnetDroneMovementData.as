class UPinballMagnetDroneMovementData : USweepingMovementData
{
	access Protected = protected, UPinballMagnetDroneMovementResolver (inherited);
	access ProtectedForMovement = protected, UBaseMovementResolver (inherited), UHazeMovementComponent (inherited);

	default DefaultResolverType = UPinballMagnetDroneMovementResolver;

	access:Protected
	bool bIsProxy = false;

	access:ProtectedForMovement
	bool PrepareProxyMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp, float DeltaTime)
	{
		if(!PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		bIsProxy = true;
		IterationTime = DeltaTime;

		return true;
	}

	access:Protected
	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		bIsProxy = false;

		const auto AttachedComp = UMagnetDroneAttachedComponent::Get(MovementComponent.Owner);
		if(AttachedComp != nullptr)
		{
			// If we just detached, always reset world up immediately
			if(AttachedComp.DetachedThisFrame())
				WorldUp = FVector::UpVector;
		}

		return true;
	}

#if EDITOR
	access:Protected
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);
		
		auto Other = Cast<UPinballMagnetDroneMovementData>(OtherBase);
		bIsProxy = Other.bIsProxy;
	}
#endif

	void AddPendingImpulses() override
	{
		FVector FrameImpulseVelocity = GetPendingImpulse();
		float Size = FrameImpulseVelocity.Size();
		FrameImpulseVelocity.X = 0;
		FrameImpulseVelocity = FrameImpulseVelocity.GetSafeNormal() * Size;
		DeltaStates.Add(EMovementIterationDeltaStateType::Impulse, GetDeltaFromVelocityInternal(FrameImpulseVelocity), FrameImpulseVelocity);
	}

	void AddHorizontalInternal(FMovementDelta HorizontalDelta, bool bIsHorizontalType) override
	{
		const FMovementDelta ConstrainedDelta = HorizontalDelta.PlaneProject(FVector::ForwardVector);
		Super::AddHorizontalInternal(ConstrainedDelta, bIsHorizontalType);
	}

	void AddVerticalInternal(FMovementDelta VerticalDelta, bool bIsVerticalType) override
	{
		const FMovementDelta ConstrainedDelta = VerticalDelta.PlaneProject(FVector::ForwardVector);
		Super::AddVerticalInternal(ConstrainedDelta, bIsVerticalType);
	}
}