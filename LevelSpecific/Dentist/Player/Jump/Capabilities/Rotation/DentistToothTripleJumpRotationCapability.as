struct FDentistToothTripleJumpRotationActivateParams
{
	float StartAngle;
	float FlipDuration;
};

class UDentistToothTripleJumpRotationCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(Dentist::Tags::BlockedWhileDash);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 120;

	UDentistToothPlayerComponent PlayerComp;
	UDentistToothJumpComponent JumpComp;
	UPlayerMovementComponent MoveComp;

	float StartAngle;
	float FlipDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
		JumpComp = UDentistToothJumpComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDentistToothTripleJumpRotationActivateParams& Params) const
	{
		if(!JumpComp.StartedJumpingThisOrLastFrame())
			return false;

		if(JumpComp.GetJumpType() != EDentistToothJump::FrontFlip)
			return false;

		FVector MeshUp = PlayerComp.GetMeshWorldRotation().UpVector.VectorPlaneProject(Player.ActorRightVector);
		Params.StartAngle = MeshUp.GetAngleDegreesTo(FVector::UpVector);

		if(MeshUp.DotProduct(Player.ActorForwardVector) > 0)
		{
			// We are leaning "forwards"
		}
		else
		{
			// We are leaning back
			Params.StartAngle = 360 - Params.StartAngle;
		}

		// Make into relative offset
		Params.StartAngle = -(360 - Params.StartAngle);

		if(Params.StartAngle < -90)
		{
			Params.StartAngle += 360;
		}

		// Remap duration to the amount left, so that the rotational speed is the same
		Params.FlipDuration = Math::Lerp(
			JumpComp.Settings.TripleJumpFlipDuration * 0.5,
			JumpComp.Settings.TripleJumpFlipDuration,
			(360 - Params.StartAngle) / 360
		);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!JumpComp.IsJumping())
			return true;

		if(JumpComp.GetJumpType() != EDentistToothJump::FrontFlip)
			return true;
		
		if(ActiveDuration > FlipDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDentistToothTripleJumpRotationActivateParams Params)
	{
		Player.BlockCapabilities(Dentist::Tags::DashLand, this);

		StartAngle = Params.StartAngle;
		FlipDuration = Params.FlipDuration;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(Dentist::Tags::DashLand, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(PlayerComp.HasSetMeshRotationThisFrame())
			return;

		const float Alpha = Math::Saturate(ActiveDuration / FlipDuration);

		const float RollAngle = Math::Lerp(StartAngle, 360, Alpha);

		FQuat SpinRotation = FQuat(FVector::RightVector, Math::DegreesToRadians(RollAngle));
		FQuat Rotation = Player.ActorTransform.TransformRotation(SpinRotation);

		if(Dentist::Jump::bApplyRotation)
			PlayerComp.SetMeshWorldRotation(Rotation, this, 0.1, DeltaTime);

#if !RELEASE
		TEMPORAL_LOG(Owner, "Rotation").Section("Triple Jump")
			.Value("StartAngle", StartAngle)
			.Value("Alpha", Alpha)
			.Value("RollAngle", RollAngle)
		;
#endif
	}
};