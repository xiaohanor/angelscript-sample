class UPlayerAimingUpdateCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = -100;

	UPlayerAimingComponent AimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AimComp.UpdateAiming();
	}
};