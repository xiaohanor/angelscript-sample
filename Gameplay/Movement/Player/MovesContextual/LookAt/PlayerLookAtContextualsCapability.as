class UPlayerLookAtContextualsCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"ContextualMoves");
	default CapabilityTags.Add(n"ContextualLookAt");
	default CapabilityTags.Add(n"LookAt");
	
	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 100;

	UHazeAnimPlayerLookAtComponent LookAtComp;
	UPlayerContextualMovesTargetingComponent TargetComp;
	UPlayerTargetablesComponent PlayerTargetablesComponent;

	private bool bHasLookAtTarget = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LookAtComp = UHazeAnimPlayerLookAtComponent::Get(Player);
		TargetComp = UPlayerContextualMovesTargetingComponent::Get(Player);
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FLookAtActivationParams& Params) const
	{
		if(LookAtComp != nullptr)
			return true;

		UHazeAnimPlayerLookAtComponent TestLookAtComp = UHazeAnimPlayerLookAtComponent::Get(Player);

		if(LookAtComp != nullptr)
		{
			Params.LookAtComp = TestLookAtComp;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FLookAtActivationParams Params)
	{
		if(LookAtComp == nullptr)
			LookAtComp = Params.LookAtComp;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UContextualMovesTargetableComponent PrimaryTarget = PlayerTargetablesComponent.GetPrimaryTarget(UContextualMovesTargetableComponent);

		if(PrimaryTarget != nullptr)
		{
			LookAtComp.SetCustomLookAtLocation(this, PrimaryTarget.WorldLocation);

			if(!bHasLookAtTarget)
				bHasLookAtTarget = true;
		}
		else if(bHasLookAtTarget)
		{
			LookAtComp.ClearCustomLookAtLocation(this);
			bHasLookAtTarget = false;
		}
	}
};

struct FLookAtActivationParams
{
	UHazeAnimPlayerLookAtComponent LookAtComp;
}