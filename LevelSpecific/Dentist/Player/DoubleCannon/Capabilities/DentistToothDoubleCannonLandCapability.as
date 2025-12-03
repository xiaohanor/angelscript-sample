class UDentistToothDoubleCannonLandCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default BlockExclusionTags.Add(Dentist::DoubleCannon::DentistDoubleCannonBlockExclusionTag);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 49;

	UDentistToothPlayerComponent PlayerComp;
	UDentistToothDoubleCannonComponent CannonComp;

	UPlayerMovementComponent MoveComp;

	FQuat InitialRotation;
	float StartAngle;
	// bool bIsRolling;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
		CannonComp = UDentistToothDoubleCannonComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PlayerComp.HasSetMeshRotationThisFrame())
			return false;

		if(!CannonComp.IsLaunched())
			return false;

		if(MoveComp.IsInAir())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PlayerComp.HasSetMeshRotationThisFrame())
			return true;

		if(ActiveDuration > CannonComp.Settings.CannonLandDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UDentistToothDoubleCannonEventHandler::Trigger_OnLanding(Player);

		InitialRotation = FQuat::MakeFromZX(FVector::UpVector, MoveComp.Velocity);
		StartAngle = PlayerComp.GetMeshWorldRotation().UpVector.GetAngleDegreesTo(FVector::UpVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float RollDuration = ActiveDuration;

		float RollAlpha = Math::Saturate(RollDuration / CannonComp.Settings.CannonLandRollDuration);

		RollAlpha = CannonComp.Settings.CannonLandRollAngleAlphaCurve.GetFloatValue(RollAlpha);
		const float RollAngle = Math::Lerp(StartAngle, 360, RollAlpha);
		const FQuat RollRotation = InitialRotation * FQuat(FVector::RightVector, Math::DegreesToRadians(RollAngle));

		if(Dentist::DoubleCannon::bApplyRotation)
			PlayerComp.SetMeshWorldRotation(RollRotation, this, -1, DeltaTime);
	}
};