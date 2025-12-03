struct FSteerSandFishInteractionActivateParams
{
	bool bWasInteraction;
}

class USteerSandFishInteractionPlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Movement;

	//default CapabilityTags.Add(ArenaSandFish::PlayerTags::ArenaSandFishPlayerInteraction);
	//default CapabilityTags.Add(ArenaSandFish::PlayerTags::ArenaSandFishPlayerSteerInteraction);

	UClimbSandFishPlayerComponent PlayerComp;
	AVortexSandFish SandFish;

	FHazeAcceleratedFloat AccSteering;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UClimbSandFishPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSteerSandFishInteractionActivateParams& Params) const
	{
		switch(Desert::GetDesertLevelState())
		{
			case EDesertLevelState::Climb:
			{
				if(!ClimbSandFish::AreBothPlayersInteracting())
					return false;

				Params.bWasInteraction = true;
				return true;
			}

			case EDesertLevelState::Steer:
			{
				return true;
			}

			default:
				return false;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		switch(Desert::GetDesertLevelState())
		{
			case EDesertLevelState::Climb:
			{
				if(!ClimbSandFish::AreBothPlayersInteracting())
					return true;

				return false;
			}

			case EDesertLevelState::Steer:
			{
				return false;
			}

			default:
				return true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSteerSandFishInteractionActivateParams Params)
	{
		SandFish = VortexSandFish::GetVortexSandFish();

		if(!Params.bWasInteraction)
		{
			USteerSandFishInteractionComponent InteractionComp = Player.Player == EHazePlayer::Mio ? SandFish.LeftInteraction : SandFish.RightInteraction;
			PlayerComp.InteractionComp = InteractionComp;
		}

		AccSteering.SnapTo(0);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(SandHand::Tags::SandHand, this);

		PlayerComp.InteractionComp.KickAnyPlayerOutOfInteraction();

		Player.AttachToComponent(PlayerComp.InteractionComp, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerComp.InteractionComp = nullptr;

		SandFish.bIsSteered = false;
		SandFish = nullptr;
		AccSteering.SnapTo(0);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(SandHand::Tags::SandHand, this);

		Player.DetachFromActor();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccSteering.AccelerateTo(GetAttributeFloat(AttributeNames::MoveRight), 0.5, DeltaTime);
		PlayerComp.InteractionComp.Steering = AccSteering.Value;

		Player.MeshOffsetComponent.SetRelativeRotation(FQuat(FVector::ForwardVector, AccSteering.Value * -0.5));
	}
};