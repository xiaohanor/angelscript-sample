struct FBattlefieldHoverboardJumpActivationParams
{
	bool bIsInJumpVolume = false;
}

class UBattlefieldHoverboardJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::Jump);
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::Hoverboard);

	default DebugCategory = n"Hoverboard";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UBattlefieldHoverboardJumpComponent JumpComp;
	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardTrickComponent TrickComp;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UBattlefieldHoverboardJumpSettings JumpSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JumpComp = UBattlefieldHoverboardJumpComponent::Get(Player);
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		TrickComp = UBattlefieldHoverboardTrickComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		JumpSettings = UBattlefieldHoverboardJumpSettings::GetSettings(Player);

		BattlefieldDevToggles::SuperJump.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBattlefieldHoverboardJumpActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!HoverboardComp.IsOn())
			return false;

		if(JumpComp.bWantToJump)
		{
			Params.bIsInJumpVolume = TrickComp.IsInsideJumpVolume();
			return true;
		}
		
		// Became airborne while inside trick volume
		if(TrickComp.HasAutoTrick()
		&& MoveComp.IsInAir() && !MoveComp.WasInAir())
		{
			Params.bIsInJumpVolume = TrickComp.IsInsideJumpVolume();
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBattlefieldHoverboardJumpActivationParams Params)
	{
		JumpComp.ConsumeJumpInput();

		FVector HorizontalVelocity = Player.ActorHorizontalVelocity;

		FVector JumpImpulseDirection;
		if(MoveComp.IsOnAnyGround())
			JumpImpulseDirection = MoveComp.CurrentGroundNormal;
		else
			JumpImpulseDirection = JumpComp.LastGroundNormal;

		FVector VelocityOppositeOfJumpDir = -JumpImpulseDirection * -JumpImpulseDirection.DotProduct(HorizontalVelocity);
		HorizontalVelocity -= VelocityOppositeOfJumpDir;

		float Impulse = 0;
		if(Params.bIsInJumpVolume)
			Impulse = TrickComp.GetLatestRampJumpVolume().RampJumpImpulse;
		else
			Impulse = JumpSettings.JumpImpulse;

		if (TrickComp.HasAutoTrick())
			Impulse *= 0.5;

		if(BattlefieldDevToggles::SuperJump.IsEnabled())
			Impulse *= 2;

		FVector JumpImpulse = JumpImpulseDirection * Impulse;

		// Player.SetActorVelocity(HorizontalVelocity + JumpImpulse);

		TEMPORAL_LOG(JumpComp).DirectionalArrow("Jump Impulse", Player.ActorLocation, JumpImpulse, 5, 40, FLinearColor::Red);

		Player.SetActorHorizontalAndVerticalVelocity(HorizontalVelocity, JumpImpulse);
		JumpComp.bJumped = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.AddGravityAcceleration();
				Movement.AddOwnerVelocity();
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			FName AnimTag = n"HoverboardJumping";
			if(TrickComp.IsInsideTrickVolume())
				AnimTag = n"HoverboardTricks";
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);
		}
	}
};