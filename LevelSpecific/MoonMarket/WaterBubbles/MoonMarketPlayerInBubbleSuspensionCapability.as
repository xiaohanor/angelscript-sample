struct FMoonMarketBubbleActivateParams
{
	AMoonMarketWaterBubble Bubble;
}

class UMoonMarketPlayerInBubbleSuspensionCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UPlayerAimingComponent AimComp;
	UMoonMarketPlayerBubbleComponent BubbleComp;
	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;

	FHazeAcceleratedVector WantedPlayerLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BubbleComp = UMoonMarketPlayerBubbleComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMoonMarketBubbleActivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(BubbleComp.CurrentBubble == nullptr)
			return false;
		
		if(BubbleComp.ShapeshiftComp.IsShapeshiftActive() && BubbleComp.ShapeshiftComp.ShapeData.bIsBubbleBlockingShape)
			return false;

		Params.Bubble = BubbleComp.CurrentBubble;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;
		
		if(BubbleComp.CurrentBubble == nullptr)
			return true;

		if(BubbleComp.ShapeshiftComp.IsShapeshiftActive() && BubbleComp.ShapeshiftComp.ShapeData.bIsBubbleBlockingShape)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMoonMarketBubbleActivateParams Params)
	{
		WantedPlayerLocation.SnapTo(Player.ActorLocation, Player.ActorVelocity);
		BubbleComp.bCanJump = false;
		BubbleComp.TargetedBubbleSceneComp = nullptr;

		FMoonMarketOnEnterBubbleEventData EventData;
		FVector TargetLocation = Params.Bubble.ActorLocation + FVector::UpVector * BubbleComp.PlayerVerticalOffsetInBubble;
		EventData.Player = Player;
		EventData.EnterLocation = Player.ActorLocation;
		EventData.EnterVelocity = (TargetLocation - Player.ActorLocation).GetSafeNormal() * Player.ActorVelocity.Size();
		UMoonMarketWaterBubbleEventHandler::Trigger_OnEnterBubble(Params.Bubble, EventData);

		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);
		Player.PlaySlotAnimation(BubbleComp.SwimAnimation);

		FAimingSettings AimSettings;
		AimSettings.bShowCrosshair = false;
		AimSettings.bCrosshairFollowsTarget = true;
		AimSettings.bApplyAimingSensitivity = false;

		AimSettings.bUseAutoAim = true;
		AimSettings.OverrideAutoAimTarget = UMoonMarketBubbleAutoAimTargetComponent;
		AimComp.StartAiming(this, AimSettings);

		Player.PlayCameraShake(BubbleComp.CameraShake, this, 0.75);
		Player.PlayForceFeedback(BubbleComp.Rumble, false, false, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BubbleComp.bCanJump = false;
		BubbleComp.CurrentBubble = nullptr;
		Player.StopSlotAnimationByAsset(BubbleComp.SwimAnimation.Animation);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		AimComp.StopAiming(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration > 0.25)
			BubbleComp.bCanJump = true;

		if(!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
		{
			BubbleComp.TargetedBubbleSceneComp = AimComp.GetAimingTarget(this).AutoAimTarget;
			FVector TargetLocation = BubbleComp.CurrentBubble.ActorLocation + FVector::UpVector * BubbleComp.PlayerVerticalOffsetInBubble;
			WantedPlayerLocation.SpringTo(TargetLocation, BubbleComp.SpringStiffness, BubbleComp.SpringDamping, DeltaTime);

			Movement.AddDeltaFromMoveToPositionWithCustomVelocity(WantedPlayerLocation.Value, WantedPlayerLocation.Velocity);
			
			FQuat TargetRotation = FQuat::MakeFromZX(FVector::UpVector, Player.GetCameraDesiredRotation().ForwardVector);

			float InterpSpeed = 0.1 + Math::Saturate(ActiveDuration) * 10;
			Movement.SetRotation(Math::QInterpConstantTo(Player.ActorQuat, TargetRotation, DeltaTime, InterpSpeed));
		}
		else
		{
			Movement.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(Movement);
	}
};