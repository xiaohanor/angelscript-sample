class USanctuaryCylindricalFlyingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"CylinderFlight");
	default CapabilityTags.Add(n"Flight");

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryFlightComponent FlightComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	USanctuaryFlightAnimationComponent AnimComp;
	USanctuaryFlightSettings Settings;

	FHazeAcceleratedRotator AccRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlightComp = USanctuaryFlightComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
		AnimComp = USanctuaryFlightAnimationComponent::Get(Owner);
		Settings = USanctuaryFlightSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (!FlightComp.bFlying)
			return false;
		return true;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (!FlightComp.bFlying)
			return true;
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AnimComp.BlendSpaceVertical.Clear(this);
		AnimComp.BlendSpaceHorizontal.Clear(this);
		AnimComp.BlendSpaceAccelerationDuration.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement))
			return;

		FVector ToCenter = (FlightComp.Center.WorldLocation - Owner.ActorCenterLocation);
		FVector CenterDir = ToCenter.GetSafeNormal();
		FVector Right = MoveComp.WorldUp.CrossProduct(CenterDir);

		if(HasControl())
		{
			FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);				
			FVector Velocity = MoveComp.Velocity;

			// Accelerate from input
			Velocity += MoveComp.WorldUp * Input.X * Settings.Acceleration * DeltaTime; 
			Velocity += Right * Input.Y * Settings.Acceleration * DeltaTime; 

			// Maintain approximate radius
			float HorizontalDistance = ToCenter.Size2D();
			float Diff = (HorizontalDistance - FlightComp.Radius);
			FVector ToCenterHorizontalDir = FVector(ToCenter.X, ToCenter.Y, 0.0) / Math::Max(1.0, HorizontalDistance);
			float ToCenterSpeed = Velocity.DotProduct(ToCenterHorizontalDir);
			float AdjustmentAcceleration = (Diff - (ToCenterSpeed * 0.3)) * Settings.Acceleration * 0.01;
			Velocity += ToCenterHorizontalDir * AdjustmentAcceleration * DeltaTime;

			// Additional acceleration from modifier capabilities
			Velocity += FlightComp.AdditionalAcceleration.Get() * DeltaTime;

			Velocity -= Velocity * Settings.Drag * DeltaTime;
			Movement.AddVelocity(Velocity);				

			Movement.AddPendingImpulses();

			// Turn towards center
			AccRotation.Value = Owner.ActorRotation;  // In case something else has rotated us
			AccRotation.AccelerateTo(CenterDir.Rotation(), Settings.TurnDuration, DeltaTime);
			Movement.SetRotation(AccRotation.Value);

			// Todo: Fix network
			AnimComp.WantedDirection.Y = Input.X;
			AnimComp.WantedDirection.X = Input.Y;

			AnimComp.BlendSpaceAcceleration.Y = Input.X * Settings.Acceleration + FlightComp.AdditionalAcceleration.Get().DotProduct(MoveComp.WorldUp);
			AnimComp.BlendSpaceAcceleration.X = Input.Y * Settings.Acceleration + FlightComp.AdditionalAcceleration.Get().DotProduct(Right);
			AnimComp.BlendSpaceAcceleration = AnimComp.BlendSpaceAcceleration.GetSafeNormal();
		}
		else
		{
			Movement.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"SanctuaryFlight");

		// Set blend space values, normal movement is -0.5..0.5
		float VerticalSpeed = MoveComp.Velocity.DotProduct(MoveComp.WorldUp);
		float VerticalBlendSpace = Math::Clamp((VerticalSpeed * 0.3) / Settings.Acceleration, -0.5, 0.5); 
		AnimComp.BlendSpaceVertical.Apply(VerticalBlendSpace, this, EInstigatePriority::Low);
		float HorizontalSpeed = MoveComp.Velocity.DotProduct(Right);
		float HorizontalBlendSpace = Math::Clamp((HorizontalSpeed * 0.3) / Settings.Acceleration, -0.5, 0.5); 
		AnimComp.BlendSpaceHorizontal.Apply(HorizontalBlendSpace, this, EInstigatePriority::Low);

		AnimComp.BlendSpaceAccelerationDuration.Apply(1.0, this, EInstigatePriority::Low);

#if EDITOR
		//FlightComp.bHazeEditorOnlyDebugBool = true;
		if (FlightComp.bHazeEditorOnlyDebugBool)
		{
			FVector Origin = FlightComp.Center.WorldLocation;
			Origin.Z = Owner.ActorLocation.Z;
			Debug::DrawDebugCylinder(Origin - FVector::UpVector * 1000.0, Origin + FVector::UpVector * 1000.0, FlightComp.Radius, 64, FLinearColor::Yellow, 2.0);
			Debug::DrawDebugLine(FlightComp.Center.WorldLocation, Origin, FLinearColor::Yellow, 50.0);
			// FVector OriginDir = (Origin - Owner.ActorLocation).GetSafeNormal();
			// Debug::DrawDebugLine(Owner.ActorLocation, Origin - OriginDir * Settings.Radius, (Origin.IsWithinDist(Owner.ActorLocation, Settings.Radius) ? FLinearColor::Red : FLinearColor::Green), 3.0, 1.0);
		}
#endif
	}
}
