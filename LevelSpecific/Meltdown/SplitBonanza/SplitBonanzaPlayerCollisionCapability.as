class USplitBonanzaPlayerCollisionCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	ASplitBonanzaManager Manager;
	UPlayerMovementComponent MoveComp;

	float StuckTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = TListedActors<ASplitBonanzaManager>().GetSingle();
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Manager.bWorldsAddedToSplit)
			return false;
		if (!Manager.bBonanzaActive)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Manager.bBonanzaActive)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TArray<int> NearbySplits;

		NearbySplits.AddUnique(Manager.SplitRenderComp.GetLevelIndexForPoint(Player.ActorLocation));
		NearbySplits.AddUnique(Manager.SplitRenderComp.GetLevelIndexForPoint(Player.ActorLocation + FVector(20, 0, 0)));
		NearbySplits.AddUnique(Manager.SplitRenderComp.GetLevelIndexForPoint(Player.ActorLocation + FVector(-20, 0, 0)));
		NearbySplits.AddUnique(Manager.SplitRenderComp.GetLevelIndexForPoint(Player.ActorLocation + FVector(0, 20, 0)));
		NearbySplits.AddUnique(Manager.SplitRenderComp.GetLevelIndexForPoint(Player.ActorLocation + FVector(0, -20, 0)));

		UPrimitiveComponent Ground = MoveComp.GetGroundContact().Component;
		TEMPORAL_LOG(this).Value(f"Ground", Ground);
		if (Ground != nullptr)
			TEMPORAL_LOG(this).Value(f"Ground Channel", Manager.ChannelsToHijack.FindIndex(Ground.CollisionObjectType));

		for (int i = 0, Count = Manager.ChannelsToHijack.Num(); i < Count; ++i)
		{
			ECollisionResponse Response = ECollisionResponse::ECR_Ignore;
			if (NearbySplits.Contains(i))
				Response = ECollisionResponse::ECR_Block;

			Player.CapsuleComponent.SetCollisionResponseToChannel(Manager.ChannelsToHijack[i], Response);

#if !RELEASE
			TEMPORAL_LOG(this)
				.Value(f"Level_{i}", Manager.SplitLines[i].AffectedLevels[0].AssetName)
				.Value(f"Player_Collision_{i}", Response != ECollisionResponse::ECR_Ignore)
			;
#endif
		}

		// Check if the player is overlapping with something blocked (ie stuck in geometry)
		// This can happen sometimes if a bonanza split closes around them
		// If the player is stuck for a little while, just kill them
		FHazeTraceSettings Trace;
		Trace.TraceWithPlayer(Player);
		FOverlapResultArray Overlaps = Trace.QueryOverlaps(Player.ActorLocation);

		if (Overlaps.HasBlockHit() && !Player.bIsControlledByCutscene)
		{
			StuckTimer += DeltaTime;
			if (StuckTimer > 0.5)
				Player.KillPlayer();
		}
		else
		{
			StuckTimer = 0.0;
		}
	}
};