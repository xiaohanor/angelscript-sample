class UDentistToothDashLandCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Dentist::Tags::BlockedWhileGroundPound);
	default CapabilityTags.Add(Dentist::Tags::CancelOnRagdoll);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 102;

	UDentistToothPlayerComponent PlayerComp;
	UDentistToothDashComponent DashComp;
	UDentistToothGroundPoundComponent GroundPoundComp;

	UPlayerMovementComponent MoveComp;

	FQuat InitialRotation;
	float StartAngle;
	bool bIsRolling;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
		DashComp = UDentistToothDashComponent::Get(Player);
		GroundPoundComp = UDentistToothGroundPoundComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PlayerComp.HasSetMeshRotationThisFrame())
			return false;

		if(DashComp.IsDashing())
			return false;

		if(!DashComp.IsLanding())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PlayerComp.HasSetMeshRotationThisFrame())
			return true;

		if(DashComp.IsDashing())
			return true;

		if(!DashComp.IsLanding())
            return true;

		if(ActiveDuration > DashComp.Settings.DashLandDuration)
			return true;

		const float StopIfInputAfterDuration = DashComp.Settings.DashLandRollDuration * DashComp.Settings.DashLandRollStopIfInputAfterAlpha;
		if(ActiveDuration > StopIfInputAfterDuration)
		{
			if(!MoveComp.MovementInput.IsNearlyZero())
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DashComp.OnStartLanding();

		bIsRolling = true;
		
		// Don't allow dashing while we are rolling
		Player.BlockCapabilities(Dentist::Tags::Dash, this);

		InitialRotation = FQuat::MakeFromZX(FVector::UpVector, MoveComp.Velocity);
		StartAngle = PlayerComp.GetMeshWorldRotation().UpVector.GetAngleDegreesTo(FVector::UpVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DashComp.OnStopLanding();

		if(bIsRolling)
		{
			bIsRolling = false;
			Player.UnblockCapabilities(Dentist::Tags::Dash, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float RollDuration = ActiveDuration;

		float RollAlpha = Math::Saturate(RollDuration / DashComp.Settings.DashLandRollDuration);

		if(HasControl())
		{
			if(bIsRolling && RollAlpha > 0.50)
			{
				CrumbStopRolling();
			}
		}

		RollAlpha = DashComp.Settings.DashLandRollAngleAlphaCurve.GetFloatValue(RollAlpha);
		const float RollAngle = Math::Lerp(StartAngle, 360, RollAlpha);
		const FQuat RollRotation = InitialRotation * FQuat(FVector::RightVector, Math::DegreesToRadians(RollAngle));

		if(Dentist::Dash::bApplyRotation)
			PlayerComp.SetMeshWorldRotation(RollRotation, this, -1, DeltaTime);

		// Snap the rotation
		// If we don't do this, then whe actor will rotate under our mesh rotation, meaning a snap when this capability deactivates.
		FQuat Rotation = FQuat::MakeFromZX(FVector::UpVector, InitialRotation.ForwardVector);
		Player.SetActorRotation(Rotation);
	}

	UFUNCTION(CrumbFunction)
	void CrumbStopRolling()
	{
		// Start allowing dashing again when we stop rolling
		bIsRolling = false;
		Player.UnblockCapabilities(Dentist::Tags::Dash, this);
	}
};