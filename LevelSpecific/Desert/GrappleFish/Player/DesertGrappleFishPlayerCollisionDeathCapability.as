class UDesertGrappleFishPlayerCollisionDeathCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"CollisionDeath");

	default TickGroup = EHazeTickGroup::LastDemotable;
	default TickGroupOrder = 100;

	bool bOnSandPreviousFrame = false;
	bool bOnSandThisFrame = false;
	float TimeWhenHitSand = 0;

	UHazeMovementComponent MoveComp;
	UDesertGrappleFishPlayerComponent PlayerComp;

	bool bHasMounted = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		PlayerComp = UDesertGrappleFishPlayerComponent::Get(Player);
		PlayerComp.OnStateChange.AddUFunction(this, n"OnPlayerStateChange");
	}

	UFUNCTION()
	private void OnPlayerStateChange(EDesertGrappleFishPlayerState NewState)
	{
		if (NewState == EDesertGrappleFishPlayerState::Riding)
			bHasMounted = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Secondary)
			return false;

		if (PlayerComp.GrappleFish == nullptr)
			return false;

		if (Player.IsPlayerDead() || Player.IsPlayerRespawning())
			return false;

		if (!bHasMounted)
			return false;

		bool bHadNonLandscapeCollision = false;

		// if (MoveComp.HasGroundContact())
		// {
		// 	if (!IsLandscape(MoveComp.GroundContact.Actor))
		// 		bHadNonLandscapeCollision = true;
		// }

		if (MoveComp.HasWallContact())
		{
			if (!IsLandscape(MoveComp.WallContact.Actor))
				bHadNonLandscapeCollision = true;
		}

		//If we are currently mounted we don't have regular movement collision, check with trace
		FHazeTraceSettings TraceSettings;
		TraceSettings.TraceWithPlayer(Player);
		TraceSettings.UseCapsuleShape(Player.CapsuleComponent.CapsuleRadius * 0.25, Player.CapsuleComponent.CapsuleHalfHeight * 0.5);
		TraceSettings.IgnoreActor(PlayerComp.GrappleFish);
		TraceSettings.IgnoreActor(PlayerComp.GrappleFish.OtherFish);
		//TraceSettings.DebugDrawOneFrame();
		FOverlapResultArray Overlaps = TraceSettings.QueryOverlaps(Player.ActorLocation);
		if (Overlaps.Num() > 0)
		{
			for (auto Overlap : Overlaps)
			{
				if (!IsLandscape(Overlap.Actor) && Overlap.bBlockingHit)
				{
					bHadNonLandscapeCollision = true;
					break;
				}
			}
		}

		if (!bHadNonLandscapeCollision)
			return false;

		if (PlayerComp.State == EDesertGrappleFishPlayerState::None)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.KillPlayer();
	}

	bool IsLandscape(AActor Actor) const
	{
		if (Actor != nullptr)
		{
			auto Landscape = UDesertLandscapeComponent::Get(Actor);
			if (Landscape != nullptr)
				return true;
		}

		return false;
	}
}