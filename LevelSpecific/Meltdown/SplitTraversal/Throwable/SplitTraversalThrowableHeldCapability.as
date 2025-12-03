class USplitTraversalThrowableHeldCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	USplitTraversalThrowablePlayerComponent ThrowableComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ThrowableComp = USplitTraversalThrowablePlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (ThrowableComp.HeldThrowable == nullptr)
			return false;
		if (ThrowableComp.HeldThrowable.bIsThrowing)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ThrowableComp.HeldThrowable == nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto Manager = ASplitTraversalManager::GetSplitTraversalManager();

		ThrowableComp.HeldThrowable.AttachToComponent(
			Player.Mesh, n"RightAttach",
		);
		ThrowableComp.HeldThrowable.SetActorRootInsideSplit(
			Manager.GetSplitForPlayer(Player)
		);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};