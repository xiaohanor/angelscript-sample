
class UPlayerPullableInputCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 150;

	UPullableComponent PullableComp;
	UPlayerPullComponent PlayerPullComp;

	UPlayerMovementComponent MoveComp;

	bool SupportsInteraction(UInteractionComponent CheckInteraction) const override
	{
		auto CheckPullComp = UPullableComponent::Get(CheckInteraction.Owner);
		return CheckPullComp != nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		PlayerPullComp = UPlayerPullComponent::GetOrCreate(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		PullableComp = UPullableComponent::Get(ActiveInteraction.Owner);
		PullableComp.StartPulling(Player, ActiveInteraction);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		PullableComp.StopPulling(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Inform the pullable of how we want to move it
		if (HasControl())
			PullableComp.ApplyPullInput(Player, MoveComp.MovementInput, DeltaTime);
	}
};