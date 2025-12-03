class UBattlefieldHoverboardSwingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swing);
	default CapabilityTags.Add(PlayerSwingTags::SwingAttach);

	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 18;
	default TickGroupSubPlacement = 1;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AHazePlayerCharacter Player;
	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;
	
	UBattlefieldHoverboardSwingComponent SwingComp;
	UPlayerTargetablesComponent TargetablesComp;

	UBattlefieldHoverboardSwingSettings SwingSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();

		SwingComp = UBattlefieldHoverboardSwingComponent::Get(Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);

		SwingSettings = UBattlefieldHoverboardSwingSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBattlefieldHoverboardSwingActivationParams& ActivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		
		if (SwingComp.Data.SwingPointToForceActivate != nullptr)
		{
			ActivationParams.SwingPoint = SwingComp.Data.SwingPointToForceActivate;
			return true;
		}

		if (!WasActionStarted(ActionNames::Grapple))
			return false;

		UTargetableComponent Targetable = TargetablesComp.GetPrimaryTarget(UContextualMovesTargetableComponent);
		USwingPointComponent TargetableSwingPointComp = Cast<USwingPointComponent>(Targetable);
		if (TargetableSwingPointComp == nullptr)
			return false;

		ActivationParams.SwingPoint = TargetableSwingPointComp;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (ActiveDuration > 0.5 && MoveComp.IsOnWalkableGround())
			return true;

		if (!SwingComp.HasActivateSwingPoint())
			return true;
		
		if(SwingComp.Data.ActiveSwingPoint == nullptr)
			return true;

		if (SwingComp.Data.ActiveSwingPoint.IsDisabled() || SwingComp.Data.ActiveSwingPoint.IsDisabledForPlayer(Player))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBattlefieldHoverboardSwingActivationParams ActivationParams)
	{
		Player.BlockCapabilities(BlockedWhileIn::Swing, this);

		SwingComp.StartSwinging(ActivationParams.SwingPoint);

		// Moved Into StartSwinging
		// ActivationParams.SwingPoint.ApplySettings(Player, this);
		// SwingComp.Data.AcceleratedTetherLength.SnapTo(SwingComp.SwingPointToPlayer.Size());

		//Reset Relevant move usages
		Player.ResetAirJumpUsage();
		Player.ResetPlayerWallRunUsage();
		Player.ResetAirDashUsage();

		SwingComp.SwingForward = Player.ActorVelocity.ConstrainToPlane(ActivationParams.SwingPoint.UpVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Swing, this);

		SwingComp.StopSwinging();
	}
}

struct FBattlefieldHoverboardSwingActivationParams
{
	USwingPointComponent SwingPoint;
}