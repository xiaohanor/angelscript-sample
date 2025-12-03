class UPinballProxyMagnetMovePredictability : UPinballMagnetDronePredictability
{
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;

	UPinballMagnetDroneComponent PinballComp;
	UPinballProxyMovementComponent MoveComp;
	UPinballMagnetAttachedMovementData MoveData;

	UPinballProxyMagnetAttachedComponent AttachedComp;
	UMagnetDroneAttachedSettings AttachedSettings;

	void Setup(APinballProxy InProxy) override
	{
		Super::Setup(InProxy);

		PinballComp = UPinballMagnetDroneComponent::Get(MagnetDrone);
		MoveComp = UPinballProxyMovementComponent::Get(Proxy);
		MoveData = MoveComp.SetupMovementData(UPinballMagnetAttachedMovementData);

		AttachedComp = UPinballProxyMagnetAttachedComponent::Get(Proxy);
		AttachedSettings = UMagnetDroneAttachedSettings::GetSettings(MagnetDrone);
	}

	bool ShouldActivate(bool bInit) override
	{
		if(MoveComp.ProxyHasMovedThisFrame())
			return false;

		if(!AttachedComp.IsAttachedToSurface())
			return false;

		return true;
	}

	bool ShouldDeactivate() override
	{
		if(MoveComp.ProxyHasMovedThisFrame())
			return true;

		if(!AttachedComp.IsAttachedToSurface())
			return true;

		return false;
	}

	void OnActivated(bool bInit) override
	{
		Super::OnActivated(bInit);
	}

	void OnDeactivated() override
	{
		Super::OnDeactivated();
	}

	void TickActive(float DeltaTime) override
	{	
		if(!MoveComp.ProxyPrepareMove(MoveData, DeltaTime, FVector::BackwardVector))
			return;

		// Make sure that the player is facing the correct direction
		MoveData.InterpRotationTo(CalculateDesiredRotation().Quaternion(), MagnetDrone::RotateSpeed, false);

		MoveData.UseGroundStickynessThisFrame();

		CalculateDeltaMove(FVector::BackwardVector, DeltaTime);

		MoveData.AddPendingImpulses();

		MoveComp.ApplyMove(MoveData);
	}

	FRotator CalculateDesiredRotation() const
	{
		// Get the desired move rotation from the velocity, or actor rotation.
		if(!MoveComp.Velocity.IsZero())
			return FRotator::MakeFromZX(Proxy.MovementWorldUp, MoveComp.Velocity);
		else
			return Proxy.ActorRotation;
	}

	void CalculateDeltaMove(FVector WorldUp, float DeltaTime) const
	{
		FVector Velocity = MoveComp.Velocity;
		FVector MovementInput = FVector(0, Proxy.TickHorizontalInput, Proxy.TickVerticalInput);
		
		FVector VerticalVelocity = Velocity.ProjectOnTo(WorldUp);
		FVector HorizontalVelocity = Velocity - VerticalVelocity;
	
		const bool bIsInputting = !MovementInput.IsNearlyZero();

		if(bIsInputting)
		{
			const bool bIsRebound = HorizontalVelocity.DotProduct(MovementInput) < 0;

			float Acceleration = PinballComp.MovementSettings.MagnetAcceleration;
			if(bIsRebound)
				Acceleration *= Math::Lerp(1, PinballComp.MovementSettings.ReboundMultiplier, MovementInput.Size());

			FVector Force = MovementInput * Acceleration;
			HorizontalVelocity += (Force * DeltaTime);

			// If we accelerated past the max, clamp
			if(IsOverHorizontalMaxSpeed(HorizontalVelocity))
				HorizontalVelocity = HorizontalVelocity.GetClampedToMaxSize(PinballComp.MovementSettings.MagnetMaxMoveSpeed);
		}

		HorizontalVelocity = Math::VInterpConstantTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, AttachedSettings.Deceleration);

		if(IsOverHorizontalMaxSpeed(HorizontalVelocity))
		{
			// Decelerate if over max speed
			HorizontalVelocity = HorizontalVelocity.GetClampedToMaxSize(AttachedSettings.MaxHorizontalSpeed);
		}

		// Gravity
		VerticalVelocity -= WorldUp * PinballComp.MovementSettings.Gravity * DeltaTime;

		Velocity = HorizontalVelocity + VerticalVelocity;

		MoveData.AddVelocity(Velocity);
	}

	bool IsOverHorizontalMaxSpeed(FVector HorizontalVelocity) const
	{
		return HorizontalVelocity.Size() > PinballComp.MovementSettings.MagnetMaxMoveSpeed;
	}

#if !RELEASE
	void LogActive(FTemporalLog SubframeLog) const override
	{
		Super::LogActive(SubframeLog);

		SubframeLog.DirectionalArrow(f"Velocity", Proxy.ActorLocation, MoveComp.Velocity);
		SubframeLog.HitResults(f"Ground", MoveComp.GroundContact.ConvertToHitResult(), MoveComp.CollisionShape, FVector::ZeroVector);
	}
#endif
}
