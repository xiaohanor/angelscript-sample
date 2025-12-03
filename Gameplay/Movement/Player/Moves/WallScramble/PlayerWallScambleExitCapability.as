class UPlayerWallScrambleExitCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::WallScramble);
	default CapabilityTags.Add(PlayerWallScrambleTags::WallScrambleExit);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 36;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerWallScrambleComponent WallScrambleComp;
	UPlayerLedgeMantleComponent MantleComp;

	bool bFollowingComponent = true;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		WallScrambleComp = UPlayerWallScrambleComponent::GetOrCreate(Player);
		MantleComp = UPlayerLedgeMantleComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!WallScrambleComp.Data.bWallScrambleComplete)
			return false;

		if (WallScrambleComp.State != EPlayerWallScrambleState::Exit)
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

		if (ActiveDuration >= WallScrambleComp.Settings.ExitDuration)
			return true;

		if (MoveComp.HasImpulse())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilitiesExcluding(BlockedWhileIn::WallScramble, n"ExcludeAirJumpAndDash", this);
		MoveComp.FollowComponentMovement(WallScrambleComp.Data.WallHit.Component, this);
		bFollowingComponent = true;

		WallScrambleComp.Data.ExitStartRotation = Owner.ActorRotation;
		WallScrambleComp.Data.bWallScrambleComplete = false;
		WallScrambleComp.Data.ExitDuration = 0.0;
		WallScrambleComp.SetState(EPlayerWallScrambleState::Exit);

		MantleComp.Data.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::WallScramble, this);
		MoveComp.UnFollowComponentMovement(this);

		WallScrambleComp.StateCompleted(EPlayerWallScrambleState::Exit);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!MoveComp.PrepareMove(Movement))
			return;

		WallScrambleComp.Data.ExitDuration += DeltaTime;

		if (HasControl())
		{
			const float HorizontalMoveStrength = Math::Clamp((ActiveDuration - WallScrambleComp.Settings.ExitNoInputDuration) / 
				WallScrambleComp.Settings.ExitNoInputBlendTime, 0.0, 1.0);

			float TargetMovementSpeed =	UPlayerAirMotionSettings::GetSettings(Player).HorizontalMoveSpeed * MoveComp.MovementSpeedMultiplier;
			FVector HorizontalVelocity = MoveComp.GetInputAdjustedHorizontalVelocity(MoveComp.HorizontalVelocity, TargetMovementSpeed, WallScrambleComp.Settings.ExitHorizontalInterpSpeed * HorizontalMoveStrength, DeltaTime);			
			Movement.AddHorizontalVelocity(HorizontalVelocity);

			//Offset the correct amount from wall
			FVector WallToPlayer = (Owner.ActorLocation - WallScrambleComp.Data.WallHit.ImpactPoint).ConstrainToPlane(MoveComp.WorldUp);
			FVector ToWallDelta = Math::VInterpTo(WallToPlayer, WallToPlayer.GetSafeNormal() * WallScrambleComp.WallSettings.TargetDistanceToWall, DeltaTime, 20) - WallToPlayer;
			Movement.AddDeltaWithCustomVelocity(ToWallDelta, FVector::ZeroVector);

			Movement.AddOwnerVerticalVelocity();
			Movement.AddGravityAcceleration();
			Movement.RequestFallingForThisFrame();
			
			const float EntryTurnPercentage = Math::Min(ActiveDuration / WallScrambleComp.Settings.ExitTurnDuration, 1.0);
			FRotator NewRotation = Owner.ActorRotation;
			if (EntryTurnPercentage < 1.0)
			{
				NewRotation = FRotator(0.0, 180.0 * EntryTurnPercentage, 0.0).Compose(WallScrambleComp.Data.ExitStartRotation);
			}
			else if (!MoveComp.MovementInput.IsNearlyZero())
			{
				const float ExitTurnStrength = Math::Clamp(ActiveDuration - WallScrambleComp.Settings.ExitTurnDuration / WallScrambleComp.Settings.ExitDuration, 0.0, 1.0);

				FRotator TargetRotation = FRotator::MakeFromXZ(MoveComp.MovementInput.GetSafeNormal(), MoveComp.WorldUp);
				NewRotation = Math::RInterpConstantTo(Owner.ActorRotation, TargetRotation, DeltaTime, 320.0 * ExitTurnStrength);		

				CheckShouldUnfollow();	
			}
			else
				CheckShouldUnfollow();
		
			Movement.SetRotation(NewRotation);	
		}
		else // Remote
		{
			Movement.ApplyCrumbSyncedAirMovement();
			Movement.RequestFallingForThisFrame();
		}

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"WallScramble");
	}

	void CheckShouldUnfollow()
	{
		if(bFollowingComponent)
		{
			MoveComp.UnFollowComponentMovement(this);
			bFollowingComponent = false;
		}
	}
}