
class UPlayerPullableMovementCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	UPullableComponent PullableComp;
	UPlayerPullComponent PlayerPullComp;

	UHazeLocomotionFeatureBase AnimFeature;

	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;

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
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		PullableComp = UPullableComponent::Get(ActiveInteraction.Owner);

		AnimFeature = PullableComp.PullAnimationFeature[Player];
		if (AnimFeature != nullptr)
			Player.AddLocomotionFeature(AnimFeature, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		if (AnimFeature != nullptr)
			Player.RemoveLocomotionFeature(AnimFeature, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Move the pullable if we want to
		PullableComp.ApplyPullableMovement(DeltaTime);

		// Expose data to the player's pull component so the animation can read it
		PlayerPullComp.WantedPullDirection = PullableComp.GetWantedPullDirection(Player);
		PlayerPullComp.ActiveTotalPullDirection = PullableComp.GetActivePullDirection();
		PlayerPullComp.bAreBothPlayersPulling = PullableComp.AreBothPlayersPulling();
		PlayerPullComp.bBothPlayersRequired = PullableComp.bRequireBothPlayers;

		// Move the player so they're in the right spot
		if (MoveComp.PrepareMove(Movement))
		{
			// Always move to 
			FVector TargetLocation = ActiveInteraction.WorldLocation;
			Movement.AddDelta(TargetLocation - Player.ActorLocation);
			Movement.SetRotation(ActiveInteraction.WorldRotation);

			FName AnimationTag = n"Pull";
			// Choose the feature's tag if we have one
			if (AnimFeature != nullptr)
				AnimationTag = AnimFeature.Tag;
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimationTag);
		}
	}
};