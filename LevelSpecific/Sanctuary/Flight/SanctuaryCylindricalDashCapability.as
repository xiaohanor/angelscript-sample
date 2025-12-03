class USanctuaryCylindricalDashCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"CylinderDash");
	default CapabilityTags.Add(n"Flight");

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryFlightComponent FlightComp;
	UPlayerMovementComponent MoveComp;
	USanctuaryFlightAnimationComponent AnimComp;
	USanctuaryFlightSettings Settings;

	float Cooldown = 0.0;
	float DashDuration = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlightComp = USanctuaryFlightComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		AnimComp = 	USanctuaryFlightAnimationComponent::Get(Player);
		Settings = USanctuaryFlightSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!FlightComp.bFlying)
			return false;
		if (!WasActionStarted(ActionNames::MovementDash))
			return false;
		if (Time::GameTimeSeconds < Cooldown)
			return false;
		return true;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!FlightComp.bFlying)
			return true;
		if (ActiveDuration > DashDuration)
		 	return true;
		if (Time::GameTimeSeconds > Cooldown)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Cooldown = Time::GameTimeSeconds + Settings.DashCooldown;
		DashDuration = Math::Min(1.0, Settings.DashCooldown * 0.9);

		FVector ToCenter = (FlightComp.Center.WorldLocation - Owner.ActorCenterLocation);
		ToCenter.Z = 0.0;
		FVector CenterDir = ToCenter.GetSafeNormal();
		FVector Right = MoveComp.WorldUp.CrossProduct(CenterDir);

		FVector ImpulseDir = FVector::ZeroVector;
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);				
		if (Input.IsNearlyZero(0.01))
		{
			ImpulseDir = MoveComp.Velocity.VectorPlaneProject(CenterDir);
		}
		else
		{
			ImpulseDir += Right * Input.Y;
			ImpulseDir += MoveComp.WorldUp * Input.X;
		}
		
		ImpulseDir.Normalize();

		Player.AddMovementImpulse(ImpulseDir * Settings.DashSpeed, n"FlightDash");

		// Snap blend space values, dash movement is -1..1
		float VerticalBlendSpace = Math::Clamp(MoveComp.WorldUp.DotProduct(ImpulseDir) * 1.42, -1.0, 1.0); 
		AnimComp.BlendSpaceVertical.Apply(VerticalBlendSpace, this, EInstigatePriority::High);
		float HorizontalBlendSpace = Math::Clamp(Right.DotProduct(ImpulseDir) * 1.42, -1.0, 1.0); 
		AnimComp.BlendSpaceHorizontal.Apply(HorizontalBlendSpace, this, EInstigatePriority::High);
		AnimComp.SnapMovementBlendSpaceValues();

		// Immediately start blending back to lower prio blend space values
		AnimComp.BlendSpaceAccelerationDuration.Apply(0.1 * DashDuration, this, EInstigatePriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector ToCenter = (FlightComp.Center.WorldLocation - Owner.ActorCenterLocation);
		ToCenter.Z = 0.0;
		FVector CenterDir = ToCenter.GetSafeNormal();
		FVector Right = MoveComp.WorldUp.CrossProduct(CenterDir);

		float VerticalSpeed = MoveComp.Velocity.DotProduct(MoveComp.WorldUp);
		float VerticalBlendSpace = Math::Clamp((VerticalSpeed * 0.3) / Settings.Acceleration, -1.0, 1.0); 
		AnimComp.BlendSpaceVertical.Apply(VerticalBlendSpace, this, EInstigatePriority::High);
		float HorizontalSpeed = MoveComp.Velocity.DotProduct(Right);
		float HorizontalBlendSpace = Math::Clamp((HorizontalSpeed * 0.3) / Settings.Acceleration, -1.0, 1.0); 
		AnimComp.BlendSpaceHorizontal.Apply(HorizontalBlendSpace, this, EInstigatePriority::High);

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AnimComp.BlendSpaceAccelerationDuration.Clear(this);
		AnimComp.BlendSpaceVertical.Clear(this);
		AnimComp.BlendSpaceHorizontal.Clear(this);
	}

	
}
