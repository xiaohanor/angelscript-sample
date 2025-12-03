class UPlayerWallScrambleJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::WallScramble);
	default CapabilityTags.Add(PlayerWallScrambleTags::WallScrambleJump);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 33;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 5, 0); 

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerWallScrambleComponent WallScrambleComp;
	UPlayerAirMotionComponent AirMotionComp;

	FVector JumpDirection;

	bool bUnblockedCapabilities = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		WallScrambleComp = UPlayerWallScrambleComponent::GetOrCreate(Player);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (WallScrambleComp.State != EPlayerWallScrambleState::Exit)
			return false;

		if (!WasActionStarted(ActionNames::MovementJump))
			return false;

		if (WallScrambleComp.Data.ExitDuration > WallScrambleComp.Settings.JumpExitAcceptanceTime)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.HasGroundContact())
			return true;

		if (MoveComp.HasImpulse())
			return true;

		if (ActiveDuration >= WallScrambleComp.Settings.JumpNoInputTime + WallScrambleComp.Settings.JumpInputBlendinTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::WallScramble, this);

		WallScrambleComp.Data.bWallScrambleComplete = false;
		WallScrambleComp.SetState(EPlayerWallScrambleState::Jump);

		JumpDirection = WallScrambleComp.Data.WallHit.ImpactNormal.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

		FVector VerticalVelocity = MoveComp.WorldUp * WallScrambleComp.Settings.JumpVerticalImpulse;
		FVector HorizontalVelocity = JumpDirection * WallScrambleComp.Settings.JumpHorizontalImpulse;
		Player.SetActorVelocity(VerticalVelocity + HorizontalVelocity);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);

		bUnblockedCapabilities = false;

		UPlayerCoreMovementEffectHandler::Trigger_WallScramble_JumpOff(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(!bUnblockedCapabilities)
			Player.UnblockCapabilities(BlockedWhileIn::WallScramble, this);

		WallScrambleComp.StateCompleted(EPlayerWallScrambleState::Jump);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!MoveComp.PrepareMove(Movement))
			return;
		
		WallScrambleComp.Data.ExitDuration += DeltaTime;
		if (ActiveDuration == 0.0)
			WallScrambleComp.AnimData.JumpRotationAngle =  Math::Min(WallScrambleComp.Data.ExitDuration / WallScrambleComp.Settings.ExitTurnDuration, 1.0) * 180.0;

		if (HasControl())
		{
			const float InputScale = (ActiveDuration - WallScrambleComp.Settings.JumpNoInputTime) / WallScrambleComp.Settings.JumpInputBlendinTime;

			FVector HorizontalVelocity = MoveComp.GetHorizontalVelocity();
			FVector VerticalVelocity = MoveComp.GetVerticalVelocity();

			HorizontalVelocity -= HorizontalVelocity * WallScrambleComp.Settings.JumpHorizontalDrag * DeltaTime;
			HorizontalVelocity = AirMotionComp.CalculateStandardAirControlVelocity(
				MoveComp.MovementInput,
				HorizontalVelocity,
				DeltaTime,
				InputScale,
			);
			
			const float GravityLerpTime = WallScrambleComp.Settings.JumpGravityBlendInTime;
			const float GravityScale = Math::Min(ActiveDuration / GravityLerpTime, 1.0);
			VerticalVelocity -= MoveComp.WorldUp * MoveComp.GravityForce * GravityScale * DeltaTime;			

			Movement.AddHorizontalVelocity(HorizontalVelocity);
			Movement.AddVerticalVelocity(VerticalVelocity);
			
			if (ActiveDuration <= WallScrambleComp.Settings.JumpNoInputTime)
			{
				const float EntryTurnPercentage = Math::Min(WallScrambleComp.Data.ExitDuration / WallScrambleComp.Settings.ExitTurnDuration, 1.0);
				FRotator NewRotation = Owner.ActorRotation;
				NewRotation = FRotator(0.0, 180.0 * EntryTurnPercentage, 0.0).Compose(WallScrambleComp.Data.ExitStartRotation);
				Movement.SetRotation(NewRotation);

			}
			else
			{
				FRotator TargetRotation = FRotator::MakeFromXZ(HorizontalVelocity.GetSafeNormal(), MoveComp.WorldUp);
				Movement.SetRotation(Math::RInterpConstantTo(Owner.ActorRotation, TargetRotation, DeltaTime, 340.0));
			}
		}
		else // Remote
		{
			Movement.ApplyCrumbSyncedAirMovement();
		}

		//Only allow airJump a certain amount into the scramble jump out.
		if (!bUnblockedCapabilities && ActiveDuration > WallScrambleComp.Settings.JumpNoInputTime)
		{
			Player.UnblockCapabilities(BlockedWhileIn::WallScramble, this);
			bUnblockedCapabilities = true;
		}

		Movement.RequestFallingForThisFrame();
		MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"WallScramble");
	}
}