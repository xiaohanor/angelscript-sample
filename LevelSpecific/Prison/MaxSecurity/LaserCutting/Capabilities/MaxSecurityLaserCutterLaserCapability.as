class UMaxSecurityLaserCutterLaserCapability : URemoteHackableBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AMaxSecurityLaserCutter Cutter;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		Cutter = Cast<AMaxSecurityLaserCutter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if (Cutter.IsStunned())
			return false;

		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		if (!Cutter.bPlayerControlled)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;

		if (Cutter.IsStunned())
			return true;

		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		if (!Cutter.bPlayerControlled)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		Cutter.ActivateLaser();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Cutter.DeactivateLaser();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);
	}
};