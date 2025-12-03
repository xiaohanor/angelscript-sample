class UPlayerSwingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swing);
	default CapabilityTags.Add(PlayerSwingTags::SwingAttach);

	// default CapabilityTags.Add(BlockedWhileIn::Swimming);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 18;
	default TickGroupSubPlacement = 1;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AHazePlayerCharacter Player;
	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;
	
	UPlayerSwingComponent SwingComp;
	UPlayerTargetablesComponent TargetablesComp;

	bool bHasResetAirActions = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();

		SwingComp = UPlayerSwingComponent::GetOrCreate(Player);
		TargetablesComp = UPlayerTargetablesComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerSwingActivationParams& ActivationParams) const
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
		
		//[AL] Workaround instead of blocking Swing during swimming due to meltdown level requirements
		if (MoveComp.HasCustomMovementStatus(n"Swimming") && TargetableSwingPointComp.bDisallowSwingFromSwimming)
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
	void OnActivated(FPlayerSwingActivationParams ActivationParams)
	{
		Player.BlockCapabilities(BlockedWhileIn::Swing, this);

		SwingComp.StartSwinging(ActivationParams.SwingPoint);

		if (ActivationParams.SwingPoint.bApplyInertiaFromMovingSwingPoint)
			MoveComp.ApplyCrumbSyncedRelativePosition(this, ActivationParams.SwingPoint, bRelativeRotation = false);
		else
			MoveComp.FollowComponentMovement(ActivationParams.SwingPoint, this, EMovementFollowComponentType::ResolveCollision, EInstigatePriority::Interaction);

		TargetablesComp.TriggerActivationAnimationForTargetableWidget(ActivationParams.SwingPoint);

		bHasResetAirActions = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Swing, this);

		SwingComp.StopSwinging();

		MoveComp.ClearCrumbSyncedRelativePosition(this);
		MoveComp.UnFollowComponentMovement(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bHasResetAirActions)
			return;

		if(ShouldResetAirActions())
		{
			//Reset Relevant move usages
			bHasResetAirActions = true;
			Player.ResetAirJumpUsage();
			Player.ResetPlayerWallRunUsage();
			Player.ResetAirDashUsage();
		}
	}

	bool ShouldResetAirActions()
	{
		//Only reset once the tether is taut and we are below the point
		return (SwingComp.Data.bTetherTaut && SwingComp.PlayerToSwingPoint.GetSafeNormal().DotProduct(MoveComp.WorldUp) > 0);

		//Verify that we are below the point
		// if(SwingComp.PlayerToSwingPoint.GetSafeNormal().DotProduct(MoveComp.WorldUp) > 0)
		// 	return true;

		// return false;
	}
}

struct FPlayerSwingActivationParams
{
	USwingPointComponent SwingPoint;
}