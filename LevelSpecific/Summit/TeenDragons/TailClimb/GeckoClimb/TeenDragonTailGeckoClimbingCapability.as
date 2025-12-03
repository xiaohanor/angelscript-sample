class UTeenDragonTailGeckoClimbingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonTailClimb);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	UHazeMovementComponent MoveComp;

	UPlayerTailTeenDragonComponent TailDragonComp;
	UTeenDragonTailGeckoClimbComponent GeckoClimbComp;
	UTeenDragonTailGeckoClimbOrientationComponent OrientationComp;
	UCameraUserComponent UserComp;

	UTeenDragonTailClimbableComponent CurrentClimbComp;

	UTeenDragonTailGeckoClimbSettings ClimbSettings;

	FVector Direction = FVector::ZeroVector;
	FHazeAcceleratedRotator AccMeshRotation;
	float CurrentSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);

		TailDragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		GeckoClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);
		OrientationComp = UTeenDragonTailGeckoClimbOrientationComponent::Get(Player);

		ClimbSettings = UTeenDragonTailGeckoClimbSettings::GetSettings(Player);
		UserComp = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!TailDragonComp.IsClimbing())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!TailDragonComp.IsClimbing())
			return true;

		if(GeckoClimbComp.bWantsToFall)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.AddMovementAlignsWithGroundContact(this, true);
		UMovementStandardSettings::SetWalkableSlopeAngle(Player, ClimbSettings.ClimbableAngle, this);

		if(TailDragonComp.bTopDownMode)
			TailDragonComp.VerticalInputInstigators.Add(this);

		Direction = Player.ActorForwardVector;
		AccMeshRotation.SnapTo(Player.Mesh.WorldRotation);

		Player.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonRoll, this);
		Player.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeFall, this);
		Player.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeDown, this);
		Player.BlockCapabilities(CameraTags::CameraChaseAssistance, this);
		Player.BlockCapabilities(TeenDragonCapabilityTags::BlockedWhileInTeenDragonClimb, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveMovementAlignsWithGroundContact(this);
		Player.ClearSettingsByInstigator(this);

		if(TailDragonComp.bTopDownMode)
			TailDragonComp.VerticalInputInstigators.RemoveSingleSwap(this);

		GeckoClimbComp.SetCameraTransitionAlphaTarget(0, ClimbSettings.CameraTransitionExitWallSpeed);

		MoveComp.ClearCurrentGroundedState();

		GeckoClimbComp.bWantsToFall = false;

		Player.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonRoll, this);
		Player.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeFall, this);
		Player.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonLedgeDown, this);
		Player.UnblockCapabilities(CameraTags::CameraChaseAssistance, this);
		Player.UnblockCapabilities(TeenDragonCapabilityTags::BlockedWhileInTeenDragonClimb, this);

		Player.ApplyBlendToCurrentView(1.5);
	}
}