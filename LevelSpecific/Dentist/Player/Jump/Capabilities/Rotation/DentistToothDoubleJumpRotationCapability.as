class UDentistToothDoubleJumpRotationCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(Dentist::Tags::BlockedWhileDash);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 110;

	UDentistToothPlayerComponent PlayerComp;
	UDentistToothJumpComponent JumpComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
		JumpComp = UDentistToothJumpComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PlayerComp.HasSetMeshRotationThisFrame())
			return false;

		if(!JumpComp.StartedJumpingThisOrLastFrame())
			return false;

		if(JumpComp.GetJumpType() != EDentistToothJump::Swirl)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PlayerComp.HasSetMeshRotationThisFrame())
			return true;

		if(!JumpComp.IsJumping())
			return true;

		if(JumpComp.GetJumpType() != EDentistToothJump::Swirl)
			return true;

		if(ActiveDuration > JumpComp.Settings.DoubleJumpSpinDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(Dentist::Tags::DashLand, this);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(Dentist::Tags::DashLand, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FQuat WorldRotation = Player.ActorQuat;
		WorldRotation = FQuat::MakeFromZX(PlayerComp.AccTiltAmount.Value, FVector::ForwardVector) * WorldRotation;

		float Alpha = Math::Saturate(ActiveDuration / JumpComp.Settings.DoubleJumpSpinDuration);
		FQuat SpinRotation = FQuat(FVector::UpVector, Math::DegreesToRadians(Alpha * 360));
		WorldRotation = WorldRotation * SpinRotation;

		if(Dentist::Jump::bApplyRotation)
			PlayerComp.SetMeshWorldRotation(WorldRotation, this, 0.2, DeltaTime);
	}
};