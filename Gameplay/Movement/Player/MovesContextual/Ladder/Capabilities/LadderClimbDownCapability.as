
class UPlayerLadderClimbDownCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Ladder);
	default CapabilityTags.Add(PlayerLadderTags::LadderClimbDown);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 25;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;
	UPlayerLadderComponent LadderComp;

	float StartUpTime = 0.3;
	float StartTimer = 0.0;

	bool bIsStandingStillOnRung = false;
	bool bStartedDeceleration = false;
	bool bStopDueToBlockingCollision = false;

	float ModifiedDecelerationSpeed = 0.0;

	FLadderRung DeceleratingToRung;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
		LadderComp = UPlayerLadderComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// If we've disabled climbing down temporarily, enable it again as soon as the
		// stick is no longer held forward
		if (LadderComp.bDisableClimbingDownUntilReInput)
		{
			if (GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).Y > -0.05)
				LadderComp.bDisableClimbingDownUntilReInput = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (LadderComp.Data.ActiveLadder == nullptr)
			return false;

		if (LadderComp.Data.ActiveLadder.IsDisabled())
			return false;

		if (LadderComp.Data.bMoving && LadderComp.State != EPlayerLadderState::TransferDown)
			return false;

		if (GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).Y > -LadderComp.Settings.VerticalDeadZone && LadderComp.State != EPlayerLadderState::TransferDown)
			return false;

		FLadderRung RungBelowPlayer = LadderComp.Data.ActiveLadder.GetClosestRungBelowWorldLocation(Player.ActorLocation);
		if (!RungBelowPlayer.IsValid() || !LadderComp.Data.ActiveLadder.TestRungForValidCollision(RungBelowPlayer, Player))
			return false;

		// If we have a ground collision we can't slide down anymore
		if (MoveComp.HasGroundContact())
			return false;

		if (LadderComp.bDisableClimbingDownUntilReInput)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		// If we've settled in place on a rung, then we can deactivate
		if (bIsStandingStillOnRung)
			return true;

		// If there are no more rungs below us, we are done
		FLadderRung RungBelowPlayer = LadderComp.Data.ActiveLadder.GetClosestRungBelowWorldLocation(Player.ActorLocation);
		if (!RungBelowPlayer.IsValid())
			return true;

		// If we have a ground collision we can't slide down anymore
		if (MoveComp.HasGroundContact())
			return true;

		if (bStopDueToBlockingCollision)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Ladder, this);
		MoveComp.FollowComponentMovement(LadderComp.Data.ActiveLadder.RootComp, this, EMovementFollowComponentType::ReferenceFrame, EInstigatePriority::Interaction);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);

		bIsStandingStillOnRung = false;
		bStartedDeceleration = false;
		LadderComp.Data.bMoving = true;
		if(LadderComp.State == EPlayerLadderState::TransferDown)
			StartTimer = StartUpTime;
		else
			StartTimer = 0.0;

		LadderComp.SetState(EPlayerLadderState::ClimbDown);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Ladder, this);
		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
		LadderComp.Data.bMoving = false;
		bStopDueToBlockingCollision = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		/*
		 * Check if remaining velocity is enough to cover another pin/step distance and if not break on current one
		 */

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{		
				FVector2D Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
				ClampInputWithinDeadZones(Input);

				float InputAlpha = Math::GetMappedRangeValueClamped(
					FVector2D(-LadderComp.Settings.VerticalDeadZone, -1),
					FVector2D(0, -1), Input.Y);

				//If we want the anticipation/windup time here then we may need to detect if we are currently sliding down / have vertical velocity
				if (StartTimer < StartUpTime)
				{
					StartTimer += DeltaTime;
					FVector NewLoc = Player.ActorLocation;
					Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, FVector::ZeroVector);

					// Allow canceling out during startup
					if (InputAlpha == 0.0)
						bIsStandingStillOnRung = true;
					else
						bIsStandingStillOnRung = false;
				}
				else
				{
					ALadder Ladder = LadderComp.Data.ActiveLadder;
					bIsStandingStillOnRung = false;

					float CurrentSpeed = LadderComp.Data.ActiveLadder.ActorUpVector.DotProduct(MoveComp.Velocity);

					// We can't slow down if we never went fast enough, so make sure we're going fast
					if (InputAlpha == 0.0 && Math::Abs(CurrentSpeed) < 150.0 && !bStartedDeceleration)
						InputAlpha = -1.0;

					FVector TargetLocation;
					if (InputAlpha < 0)
					{
						//We are currently sliding down based on input

						FLadderRung RungBelowPlayer = Ladder.GetClosestRungBelowWorldLocation(Player.ActorLocation);
						if (!Ladder.TestRungForValidCollision(RungBelowPlayer, Player))
						{
							if(RungBelowPlayer.RungIndex != Ladder.GetClosestRungToWorldLocation(Player.ActorLocation).RungIndex )
								TargetLocation = Ladder.GetRungWorldLocation(Ladder.GetClosestRungToWorldLocation(Player.ActorLocation));
							else
								TargetLocation = Ladder.GetRungWorldLocation(Ladder.GetClosestRungAboveWorldLocation(Player.ActorLocation));
							
							bStopDueToBlockingCollision = true;

						}
						else
						{
							CurrentSpeed += ((MoveComp.GravityForce * LadderComp.Settings.SlideGravityScalar) * InputAlpha) * DeltaTime;
							CurrentSpeed = Math::Max(CurrentSpeed, -LadderComp.Settings.TerminalSlideSpeed);
							TargetLocation = Player.ActorLocation + (LadderComp.Data.ActiveLadder.ActorUpVector * CurrentSpeed) * DeltaTime;

							bStartedDeceleration = false;
						}
					}
					else
					{
						if (!bStartedDeceleration)
						{
							// How long will it take to decelerate
							float DecelerationTime = Math::Abs(CurrentSpeed / LadderComp.Settings.SlideDecelerationSpeed);
							float DecelerationDistance = Math::Abs(CurrentSpeed) * DecelerationTime * 0.5;

							// Calculate which rung we're going to end up on
							FLadderRung RungBelowPlayer = Ladder.GetClosestRungBelowWorldLocation(Player.ActorLocation);
							FLadderRung ClosestTargetRung = Ladder.GetClosestRungToWorldLocation(Player.ActorLocation - Ladder.ActorUpVector * DecelerationDistance);

							// We can only go to rungs below the player, never above
							if (RungBelowPlayer.IsValid())
								DeceleratingToRung.RungIndex = Math::Min(RungBelowPlayer.RungIndex, ClosestTargetRung.RungIndex);

							FVector DeceleratingToLocation = Ladder.GetRungWorldLocation(DeceleratingToRung);
							FVector DeceleratingDelta = DeceleratingToLocation - Player.ActorLocation;

							float RealDecelerationDistance = Math::Abs(DeceleratingDelta.DotProduct(Ladder.ActorUpVector));
							float RealDecelerationTime = RealDecelerationDistance * 2.0 / Math::Abs(CurrentSpeed);

							ModifiedDecelerationSpeed = Math::Abs(CurrentSpeed) / RealDecelerationTime;
							bStartedDeceleration = true;
						}

						// Make sure we reach and don't overshoot the rung we targeted for deceleration
						FVector RungLocation = Ladder.GetRungWorldLocation(DeceleratingToRung);
						float HeightDeltaToRung = (RungLocation - Player.ActorLocation).DotProduct(Ladder.ActorUpVector);

						CurrentSpeed = Math::Min(CurrentSpeed + ModifiedDecelerationSpeed * DeltaTime, 0.0);

						float WantedDelta = Math::Min(CurrentSpeed, -50.0) * DeltaTime;
						if (Math::Abs(HeightDeltaToRung) < Math::Max(Math::Abs(WantedDelta), 1.0))
						{
							TargetLocation = RungLocation;
							bIsStandingStillOnRung = true;
						}
						else
						{
							bIsStandingStillOnRung = false;

							TargetLocation = Player.ActorLocation + (LadderComp.Data.ActiveLadder.ActorUpVector * WantedDelta);
						}
					}

					FVector DeltaMove = TargetLocation - Player.ActorLocation;

					Movement.AddDelta(DeltaMove);
					Movement.SetRotation(LadderComp.CalculatePlayerCapsuleRotation(LadderComp.Data.ActiveLadder));

					FHazeFrameForceFeedback FF;
					FF.LeftMotor = Math::Sin(ActiveDuration * 40.0) * 0.2;
					FF.RightMotor = Math::Sin(-ActiveDuration * 40.0) * 0.2;
					Player.SetFrameForceFeedback(FF);
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			
			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"LadderClimb", this);
		}
	}

	void ClampInputWithinDeadZones(FVector2D& Input)
	{
		if(Input.Y > -LadderComp.Settings.VerticalDeadZone && Input.Y < LadderComp.Settings.VerticalDeadZone)
			Input.Y = 0.0;

		if(Input.X > -LadderComp.Settings.HorizontalDeadZone && Input.X < LadderComp.Settings.HorizontalDeadZone)
			Input.X = 0.0;
	}
};

