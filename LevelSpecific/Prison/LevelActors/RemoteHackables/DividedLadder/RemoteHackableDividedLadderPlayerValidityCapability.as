class URemoteHackableDividedLadderPlayerValidityCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	URemoteHackableDividerLadderPlayerValidityComponent LadderComp;
	ARemoteHackableDividedLadder Ladder;
	UHazeMovementComponent MoveComp;

	bool bInValidRange = false;
	bool bClimbingLadder = false;

	UBoxComponent AboveBlocker;
	bool bAboveBlockerEnabled = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LadderComp = URemoteHackableDividerLadderPlayerValidityComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (LadderComp.Ladder == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (LadderComp.Ladder == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Ladder = LadderComp.Ladder;
		bClimbingLadder = false;
		bAboveBlockerEnabled = false;
		bInValidRange = true;
		UpdateAboveBlockerStatus(false);

		AboveBlocker = Player.IsMio() ? Ladder.MioAboveBlocker : Ladder.ZoeAboveBlocker;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (!bInValidRange)
		{
			Player.UnblockCapabilities(PlayerMovementTags::Ladder, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float HeightDif = Player.ActorLocation.Z - Ladder.RemoteHackingResponseComp.WorldLocation.Z;

		if (bInValidRange)
		{
			if (HeightDif < -170.0 || (HeightDif > 70.0 && !Ladder.TopSegmentConnected()))
			{
				bInValidRange = false;
				Player.BlockCapabilities(PlayerMovementTags::Ladder, this);
			}
		}
		else
		{
			if (HeightDif >= -170.0 && (HeightDif <= 70.0 || Ladder.TopSegmentConnected()))
			{
				bInValidRange = true;
				Player.UnblockCapabilities(PlayerMovementTags::Ladder, this);
			}
		}

		if (Ladder.TopSegmentConnected())
		{
			UpdateAboveBlockerStatus(false);
		}
		else if (bClimbingLadder)
		{
			if (!Player.IsAnyCapabilityActive(PlayerMovementTags::Ladder))
				StopClimbingLadder();
		}
		else
		{
			if (Player.IsAnyCapabilityActive(PlayerMovementTags::Ladder))
				StartClimbingLadder();
		}
	}

	void StartClimbingLadder()
	{
		bClimbingLadder = true;
		AboveBlocker.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		UpdateAboveBlockerStatus(true);
	}

	void StopClimbingLadder()
	{
		bClimbingLadder = false;
		UpdateAboveBlockerStatus(false);
	}

	void UpdateAboveBlockerStatus(bool bBlock)
	{
		if (!bBlock)
		{
			if (bAboveBlockerEnabled)
			{
				bAboveBlockerEnabled = false;
				AboveBlocker.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			}
		}
		else if (bBlock)
		{
			if (!bAboveBlockerEnabled)
			{
				bAboveBlockerEnabled = true;
				AboveBlocker.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
			}
		}
	}
}

class URemoteHackableDividerLadderPlayerValidityComponent : UActorComponent
{
	ARemoteHackableDividedLadder Ladder;
}