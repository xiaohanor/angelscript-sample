struct FCentipedeBiteActivationCapabilityActivationParams
{
	UCentipedeBiteResponseComponent BiteResponseComponent = nullptr;
}

// Used for network activation, but also handles local biting
class UCentipedeBiteActivationCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CentipedeTags::Centipede);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	UPlayerCentipedeComponent CentipedeComponent;
	UCentipedeBiteComponent CentipedeBiteComponent;
	UPlayerTargetablesComponent TargetablesComponent;

	UCentipedeBiteSettings Settings;

	// This flag is used to deactivate if remote side has bitten component already
	bool bShouldAbort = false;

	// Will hold the current component whether activation was valid or not
	UCentipedeBiteResponseComponent CurrentBiteResponseComponent = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Owner);
		CentipedeBiteComponent = UCentipedeBiteComponent::Get(Owner);
		TargetablesComponent = UPlayerTargetablesComponent::Get(Owner);

		Settings = UCentipedeBiteSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCentipedeBiteActivationCapabilityActivationParams& ActivationParams) const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return false;

		if (!CentipedeBiteComponent.GetBiteActionStarted(this))
			return false;

		// Check if we were previously targeting something, which uh we should
		UCentipedeBiteResponseComponent TargetableComponent = CentipedeBiteComponent.GetTargetedComponent();
		if (TargetableComponent == nullptr)
		{
			// Double check
			TargetableComponent = TargetablesComponent.GetPrimaryTarget(UCentipedeBiteResponseComponent);
			if (TargetableComponent == nullptr)
				return false;
		}

		// Is the target bitten?
		if (TargetableComponent.IsBitten())
			return false;

		ActivationParams.BiteResponseComponent = TargetableComponent;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Deactivate if component being bitten was disabled
		if (CentipedeBiteComponent.IsBitingSomething())
		{
			if (CentipedeBiteComponent.GetBittenComponent().IsDisabledForPlayer(Player))
				return true;

			if (!CentipedeBiteComponent.GetBiteActioning(this) && ActiveDuration > Settings.MinimumBiteDuration)
				return true;
		}
		else
		{
			// We couldn't get lock, bail!
			return true;
		}

		if (bShouldAbort)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FCentipedeBiteActivationCapabilityActivationParams ActivationParams)
	{
		bShouldAbort = false;
		CurrentBiteResponseComponent = ActivationParams.BiteResponseComponent;

		// Try to acquire lock
		CurrentBiteResponseComponent.NetworkLockComponent.Acquire(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CentipedeBiteComponent.ClearPendingBite(FInstigator(this, CurrentBiteResponseComponent.Owner.Name));

		// Leave centipede bite response component guy alone!
		CurrentBiteResponseComponent.NetworkLockComponent.Release(Player, this);
		CurrentBiteResponseComponent = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Bail if other player has lock
		if (CurrentBiteResponseComponent.NetworkLockComponent.IsAcquired(Player.OtherPlayer))
		{
			bShouldAbort = true;
			return;
		}

		// Bite away!
		if (CurrentBiteResponseComponent.NetworkLockComponent.IsAcquired(Player) && !CurrentBiteResponseComponent.IsBitten())
			CentipedeBiteComponent.ApplyPendingBite(CurrentBiteResponseComponent, FInstigator(this, CurrentBiteResponseComponent.Owner.Name));
	}
}