class USummitBreakingGapCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	ASummitBreakingGap BreakingGap;

	float StartingDistance;
	FVector StartLocation;

	FHazeAcceleratedFloat AccMovePercentage;

	bool bFinishedMoving;

	FVector Velocity;
	

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BreakingGap = Cast<ASummitBreakingGap>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!BreakingGap.bIsActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!BreakingGap.bIsActive)
			return true;

		if (bFinishedMoving)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartLocation = BreakingGap.MeshRoot.RelativeLocation;
		AccMovePercentage.SnapTo(0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BreakingGap.bIsActive = false;
	}

	AHazePlayerCharacter GetTargetPlayer()
	{
		FVector CheckLocation = BreakingGap.DistanceLocationCheck.WorldLocation;
		AHazePlayerCharacter TargetPlayer = Game::Mio;

		if (Game::Mio.ActorLocation.DistSquared(CheckLocation) < Game::Zoe.ActorLocation.DistSquared(CheckLocation))
		{
			TargetPlayer = Game::Zoe;
		}
		if ((TargetPlayer.IsPlayerDead() || TargetPlayer.IsPlayerRespawning()))
		{
			TargetPlayer = TargetPlayer.OtherPlayer;
		}
		return TargetPlayer;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			auto TargetPlayer = GetTargetPlayer();
			auto User = UCameraUserComponent::Get(TargetPlayer);

			FVector CameraLocation = User.ViewLocation;

			FVector Delta = CameraLocation - BreakingGap.DistanceLocationCheck.WorldLocation;
			float Dist = BreakingGap.ActorForwardVector.DotProduct(Delta);

			float MovePercentage = 1 - Math::Saturate(Math::NormalizeToRange(Dist, 0, BreakingGap.TotalDistance));
			if (MovePercentage > AccMovePercentage.Value)
				AccMovePercentage.AccelerateTo(MovePercentage, 0.5, DeltaTime);

			FVector TargetLocation = Math::Lerp(StartLocation, FVector(0), AccMovePercentage.Value);
			BreakingGap.MeshRoot.RelativeLocation = TargetLocation;
			BreakingGap.CrumbLocation.Value = BreakingGap.MeshRoot.RelativeLocation;
			
			if (BreakingGap.bDebug)
			{
				PrintToScreen("Percentage: " + MovePercentage);
				PrintToScreen("Dist: " + Dist);
				PrintToScreen("NormalizedToRange: " + Math::NormalizeToRange(Dist, 0, BreakingGap.TotalDistance));
			}

			if (!bFinishedMoving)
				bFinishedMoving = MovePercentage >= 1.0;
		}
		else
		{
			BreakingGap.MeshRoot.RelativeLocation = BreakingGap.CrumbLocation.Value;
		}
	}
};