struct FCentipedeSwingBiteCapabilityActivationParams
{
	UCentipedeSwingPointComponent SwingPoint = nullptr;
}

// Capability is used for mutexing swing bite
class UCentipedeSwingBiteActivationCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CentipedeTags::Centipede);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	// Tick before CentipedeSwingBiteCapability
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 99;

	UCentipedeBiteComponent BiteComponent;
	UPlayerCentipedeSwingComponent SwingComponent;
	UPlayerTargetablesComponent TargetablesComponent;

	// This flag is used to deactivate if remote side has bitten component already
	bool bShouldAbort;

	// Will hold the current component whether activation was valid or not
	UCentipedeSwingPointComponent CurrentSwingPoint = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BiteComponent = UCentipedeBiteComponent::Get(Owner);
		SwingComponent = UPlayerCentipedeSwingComponent::Get(Owner);
		TargetablesComponent = UPlayerTargetablesComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCentipedeSwingBiteCapabilityActivationParams& ActivationParams) const
	{
		if (!BiteComponent.GetBiteActionStarted(this))
			return false;

		UCentipedeSwingPointComponent SwingPoint = TargetablesComponent.GetPrimaryTarget(UCentipedeSwingPointComponent);
		if (SwingPoint == nullptr)
			return false;

		ActivationParams.SwingPoint = SwingPoint;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// This can happen if, for instance, a forced jump was activated
		UCentipedeSwingPointComponent ActiveSwingPoint = SwingComponent.GetActiveSwingPoint();
		if (ActiveSwingPoint == nullptr)
			return true;

		if (SwingComponent.GetActiveSwingPoint().bCanPlayerLetGo)
		{
			if (!BiteComponent.GetBiteActioning(this) && ActiveDuration > SwingComponent.Settings.MinimumBiteDuration)
				return true;
		}

		// We didn't get lock, deactivate
		if (bShouldAbort)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FCentipedeSwingBiteCapabilityActivationParams ActivationParams)
	{
		bShouldAbort = false;
		CurrentSwingPoint = ActivationParams.SwingPoint;

		// We don't care about normal biting 
		Player.BlockCapabilities(CentipedeTags::CentipedeBite, this);

		// Try to acquire lock
		// CurrentSwingPoint.NetworkLockComponent.Acquire(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Release lock
		// CurrentSwingPoint.NetworkLockComponent.Release(Player, this);
		CurrentSwingPoint = nullptr;

		Player.UnblockCapabilities(CentipedeTags::CentipedeBite, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Bail if other player has lock
		// if (CurrentSwingPoint.NetworkLockComponent.IsAcquired(Player.OtherPlayer))
		// {
		// 	bShouldAbort = true;
		// 	return;
		// }

		// Bite swing if player has lock
		// if (CurrentSwingPoint.NetworkLockComponent.IsAcquired(Player))
		{
			if (!CurrentSwingPoint.IsOccupied())
			{
				SwingComponent.WritePendingSwingPoint(CurrentSwingPoint);
			}
		}
	}
}