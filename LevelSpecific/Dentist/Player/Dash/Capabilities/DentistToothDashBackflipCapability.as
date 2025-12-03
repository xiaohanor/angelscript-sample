struct FDentistToothDashBackflipActivateParams
{
	float BackflipDuration;
};

class UDentistToothDashBackflipCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Dentist::Tags::BlockedWhileGroundPound);
	default CapabilityTags.Add(Dentist::Tags::CancelOnRagdoll);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 102;

	UDentistToothPlayerComponent PlayerComp;
	UDentistToothDashComponent DashComp;
	UPlayerMovementComponent MoveComp;

	float StartAngle;
	float FlipDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
		DashComp = UDentistToothDashComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDentistToothDashBackflipActivateParams& Params) const
	{
		if(PlayerComp.HasSetMeshRotationThisFrame())
			return false;

		if(DashComp.IsDashing())
			return false;

		if(!DashComp.IsBackflipping())
			return false;

		Params.BackflipDuration = DashComp.GetBackflipDuration();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PlayerComp.HasSetMeshRotationThisFrame())
			return true;

		if(DashComp.IsDashing())
			return true;

		if(!DashComp.IsBackflipping())
			return true;

		if(ActiveDuration > FlipDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDentistToothDashBackflipActivateParams Params)
	{
		DashComp.OnStartBackflipping();

		StartAngle = PlayerComp.GetMeshWorldRotation().UpVector.GetAngleDegreesTo(FVector::UpVector);

		// Remap duration to the amount left, so that the rotational speed is the same
		FlipDuration = (1.0 - (StartAngle / 360)) * Params.BackflipDuration;

		Player.BlockCapabilities(Dentist::Tags::Dash, this);
		Player.BlockCapabilities(Dentist::Tags::OrientToVelocity, this);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DashComp.OnStopBackflipping();

		Player.UnblockCapabilities(Dentist::Tags::Dash, this);
		Player.UnblockCapabilities(Dentist::Tags::OrientToVelocity, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(PlayerComp.HasSetMeshRotationThisFrame())
			return;

		float Alpha = Math::Saturate(ActiveDuration / FlipDuration);

		Alpha = Math::EaseOut(0, 1, Alpha, DashComp.Settings.BackflipExponent);

		const float TargetRollAngle = DashComp.Settings.bActuallyDoABackflip ? -360 : 0;
		const float RollAngle = Math::Lerp(StartAngle, TargetRollAngle, Alpha);
		FQuat SpinRotation = FQuat(FVector::RightVector, Math::DegreesToRadians(RollAngle));
		FQuat Rotation = Player.ActorTransform.TransformRotation(SpinRotation);

		if(Dentist::Dash::bApplyRotation)
			PlayerComp.SetMeshWorldRotation(Rotation, this, 0.1, DeltaTime);
	}
};