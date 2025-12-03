
class UPlayerLadderClimbUpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Ladder);
	default CapabilityTags.Add(PlayerLadderTags::LadderClimbUp);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 25;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;
	UPlayerLadderComponent LadderComp;

	FVector TargetLocation;
	bool bIsStandingStillOnRung = false;

	//
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
		// If we've disabled climbing up temporarily, enable it again as soon as the
		// stick is no longer held forward
		if (LadderComp.bDisableClimbingUpUntilReInput)
		{
			if (GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).Y < 0.05)
				LadderComp.bDisableClimbingUpUntilReInput = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (LadderComp.Data.ActiveLadder == nullptr)
			return false;

		if(LadderComp.Data.ActiveLadder.IsDisabled())
			return false;

		if (LadderComp.Data.bMoving)
			return false;

		if (GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).Y < 0.25)
			return false;

		FLadderRung RungAbovePlayer = LadderComp.Data.ActiveLadder.GetClosestRungAboveWorldLocation(Player.ActorLocation);
		if (!RungAbovePlayer.IsValid())
			return false;

		if (!LadderComp.Data.ActiveLadder.TestRungForValidCollision(RungAbovePlayer, Player))
			return false;

		// If we have a ceiling collision we can't climb up anymore
		if (MoveComp.HasCeilingContact())
			return false;

		if (LadderComp.bDisableClimbingUpUntilReInput)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FLadderClimbDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			{
				Params.bMoveInterrupted = true;
				return true;
			}

		// If we've settled in place on a rung, then we can deactivate
		if (bIsStandingStillOnRung)
			return true;

		// If there are no more rungs above us, we are done
		FLadderRung RungAbovePlayer = LadderComp.Data.ActiveLadder.GetClosestRungAboveWorldLocation(Player.ActorLocation);
		if (!RungAbovePlayer.IsValid())
			return true;

		if (!LadderComp.Data.ActiveLadder.TestRungForValidCollision(RungAbovePlayer, Player))
			return true;

		// If we have a ceiling collision we can't climb up anymore
		if (MoveComp.HasCeilingContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Ladder, this);
		MoveComp.FollowComponentMovement(LadderComp.Data.ActiveLadder.RootComp, this, EMovementFollowComponentType::ReferenceFrame, EInstigatePriority::Interaction);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);

		LadderComp.SetState(EPlayerLadderState::ClimbUp);
		LadderComp.Data.bMoving = true;
		bIsStandingStillOnRung = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FLadderClimbDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::Ladder, this);
		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);

		if(Params.bMoveInterrupted)
			return;

		LadderComp.Data.bMoving = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{		
				ALadder Ladder = LadderComp.Data.ActiveLadder;

				bIsStandingStillOnRung = false;

				FVector NewLoc = Player.ActorLocation + Ladder.ActorUpVector * LadderComp.Settings.ClimbUpSpeed * DeltaTime;

				// If we are no longer holding input, we want to keep going until we hit the next rung
				bool bIsInputtingUp = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).Y >= 0.25;
				if (!bIsInputtingUp)
				{
					FLadderRung ClosestRung = Ladder.GetClosestRungToWorldLocation(Player.ActorLocation);
					FVector ClosestRungLocation = Ladder.GetRungWorldLocation(ClosestRung);
					float ClosestRungVerticalDistance = (ClosestRungLocation - Player.ActorLocation).ConstrainToPlane(Ladder.ActorUpVector.CrossProduct(Ladder.ActorForwardVector)).Size();

					if (ClosestRungVerticalDistance < 1.0)
					{
						// We are currently standing on a rung, so we want to stop
						NewLoc = ClosestRungLocation;
						bIsStandingStillOnRung = true;
					}
					else
					{
						// We are not standing on a rung, so keep going until the next run, but don't overshoot it
						FLadderRung NextRung = Ladder.GetClosestRungAboveWorldLocation(Player.ActorLocation);
						FVector NextRungLocation = Ladder.GetRungWorldLocation(NextRung);

						float HeightDeltaToNextRung = (NextRungLocation - Player.ActorLocation).DotProduct(Ladder.ActorUpVector);
						float HeightDeltaToClimb = (NewLoc - Player.ActorLocation).DotProduct(Ladder.ActorUpVector);
						if (HeightDeltaToNextRung < HeightDeltaToClimb)
							NewLoc = Player.ActorLocation + Ladder.ActorUpVector * HeightDeltaToNextRung;
					}
				}

				Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, FVector::ZeroVector);
				Movement.SetRotation(LadderComp.CalculatePlayerCapsuleRotation(Ladder));
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			
			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"LadderClimb", this);
		}
	}
};

struct FLadderClimbDeactivationParams
{
	bool bMoveInterrupted = false;
}
