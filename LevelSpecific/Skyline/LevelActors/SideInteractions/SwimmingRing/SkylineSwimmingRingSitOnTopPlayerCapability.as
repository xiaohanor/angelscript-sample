struct FSkylineSwimmingRingSitOnTopPlayerActivationParams
{
	ASkylineSwimmingRing OccupiedRing;
	bool bWasSwimming = false;
}

struct FSkylineSwimmingRingSitOnTopPlayerDeactivationParams
{
	bool bNormal = false;
}

class USkylineSwimmingRingSitOnTopPlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	// default CapabilityTags.Add(CapabilityTags::);
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;

	FSkylineSwimmingRingSitOnTopPlayerActivationParams ActivationParams;

	USkylineSwimmingRingPlayerComponent RingOccupationComp;
	UPlayerJumpComponent JumpComp;
	UPlayerMovementComponent MoveComp;
    USimpleMovementData Movement;

	FHazeAnimationDelegate EnterBlendOutDelegate;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RingOccupationComp = USkylineSwimmingRingPlayerComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::GetOrCreate(Player);
		JumpComp = UPlayerJumpComponent::GetOrCreate(Player);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineSwimmingRingSitOnTopPlayerActivationParams& Params) const
	{
		if (RingOccupationComp.OccupiedRing == nullptr)
			return false;
		Params.OccupiedRing = RingOccupationComp.OccupiedRing;
		Params.bWasSwimming = !MoveComp.IsInAir();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSkylineSwimmingRingSitOnTopPlayerDeactivationParams& Params) const
	{
		if (TryingToJump())
		{
			Params.bNormal = true;
			return true;
		}
		if (Player.IsPlayerDead())
		{
			Params.bNormal = true;
			return true;
		}
		if (RingOccupationComp.OccupiedRing == nullptr)
		{
			Params.bNormal = true;
			return true;
		}
		return false;
	}

	bool TryingToJump() const
	{
		if (!WasActionStartedDuringTime(ActionNames::MovementJump, JumpComp.Settings.InputBufferWindow) && !JumpComp.IsJumpBuffered())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineSwimmingRingSitOnTopPlayerActivationParams Params)
	{
		RingOccupationComp.OccupiedRing = Params.OccupiedRing;
		RingOccupationComp.OccupiedRing.bOccupied = true;
		if (Player.IsMio())
			RingOccupationComp.OccupiedRing.FauxTranslationMio.ApplyImpulse(Player.ActorLocation, -FVector::UpVector * 600.0);
		else
			RingOccupationComp.OccupiedRing.FauxTranslationZoe.ApplyImpulse(Player.ActorLocation, -FVector::UpVector * 600.0);

		ActivationParams = Params;
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);

		bool bAttach1IsUp = ActivationParams.OccupiedRing.PlayerAttachComp1.UpVector.DotProduct(FVector::UpVector) > 0.0;
		USceneComponent AttachComp = ActivationParams.OccupiedRing.PlayerAttachComp2;
		if (bAttach1IsUp)
			AttachComp = ActivationParams.OccupiedRing.PlayerAttachComp1;

		AttachComp.SetWorldRotation(FRotator::MakeFromZX(AttachComp.UpVector, Player.ActorForwardVector));
		Player.AttachToComponent(AttachComp);
		Player.ResetMovement();

		FSkylineSwimmingRingEventData Data;
		Data.Player = Player;
		float BlendTime = 0.2;
		if (Params.bWasSwimming)
		{
			BlendTime = 0;
			USkylineSwimmingRingEventHandler::Trigger_OnPlayerEnterSwimIntoFromBelow(RingOccupationComp.OccupiedRing, Data);
		}
		else
			USkylineSwimmingRingEventHandler::Trigger_OnPlayerEnterJumpIntoFromAbove(RingOccupationComp.OccupiedRing, Data);

		UAnimSequence EnterAnim = Params.bWasSwimming ? ActivationParams.OccupiedRing.EnterAnimBottom : ActivationParams.OccupiedRing.EnterAnimTop;
		if (EnterAnim!= nullptr)
		{
			EnterBlendOutDelegate.BindUFunction(this, n"OnEnterAnimationFinished");
			Player.PlaySlotAnimation(
				OnBlendedIn =  FHazeAnimationDelegate(),
				OnBlendingOut = EnterBlendOutDelegate,
				Animation = EnterAnim,
				bLoop = false,
				BlendType = EHazeBlendType::BlendType_Inertialization,
				BlendTime = BlendTime,
			);
		}
	}

	UFUNCTION()
	void OnEnterAnimationFinished()
	{
		if (IsActive())
		{
			Player.PlaySlotAnimation(
				OnBlendedIn =  FHazeAnimationDelegate(),
				OnBlendingOut = FHazeAnimationDelegate(),
				Animation = ActivationParams.OccupiedRing.SitInRingAnim,
				bLoop = true,
				BlendType = EHazeBlendType::BlendType_Inertialization,
				BlendTime = 0.4,
			);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSkylineSwimmingRingSitOnTopPlayerDeactivationParams Params)
	{
		if (!Params.bNormal)
			return;
		
		FSkylineSwimmingRingEventData Data;
		Data.Player = Player;
		USkylineSwimmingRingEventHandler::Trigger_OnPlayerLeaveJumpOut(RingOccupationComp.OccupiedRing, Data);
		// Player.ClearPointOfInterestByInstigator(this);

		Player.DetachFromActor();

		ActivationParams.OccupiedRing.TimeSinceOccupied = 0.0;
		ActivationParams.OccupiedRing.bOccupied = false;
		ActivationParams.OccupiedRing.FauxPlayerImpulseRotateComp.ApplyImpulse(Player.ActorLocation, -FVector::UpVector * 500.0);

		RingOccupationComp.OccupiedRing = nullptr;

		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);

		EnterBlendOutDelegate.Clear();
		Player.StopSlotAnimation();
		Player.AddMovementImpulseToReachHeight(200.0);

		Player.RequestLocomotion(n"Jump", this);
	}
};