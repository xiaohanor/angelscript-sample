class USkylineGeckoArenaBoundsKillCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ArenaBoundsDeath");
	default TickGroup = EHazeTickGroup::BeforeGameplay;

	// Run on control side only
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	ASkylineTorReferenceManager Arena;
	UBasicAIHealthComponent HealthComp;
	USkylineGeckoComponent GeckoComp;
	UHazeActorRespawnableComponent RespawnComp;
	UBasicAIAnimationComponent AnimComp;
	USkylineGeckoSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Arena = TListedActors<ASkylineTorReferenceManager>().GetSingle();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		GeckoComp = USkylineGeckoComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		Settings = USkylineGeckoSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;
		if (HealthComp.IsDead())
			return false;
		if (Time::GetGameTimeSince(RespawnComp.SpawnTime) < 8.0)
			return false;
		if (IsInsideSafeBounds())
			return false;
		return true;
	}

	bool IsInsideSafeBounds() const
	{
		float SafeRadius = Settings.ArenaDeathBoundsRadius;
		float SafeBelow = Settings.ArenaDeathBoundsBelow;
		float SafeAbove = Settings.ArenaDeathBoundsAbove;
	
		// Safety hack: if for some reason a gecko has become stuck outside arena, but inside safe bounds we should kill it. 
		bool bHackShrinkSafeSpace = ShouldHackShrinkSafeSpace();
		if (bHackShrinkSafeSpace)
		{
			SafeRadius = 1800.0;
			SafeBelow = 20.0;
			SafeAbove = 600.0;
		}
		FVector ArenaCenter = Arena.ArenaCenter.ActorLocation;
		if (!Math::IsWithin(Owner.ActorLocation.Z, ArenaCenter.Z - SafeBelow, ArenaCenter.Z + SafeAbove))
			return false;
		if (!Owner.ActorLocation.IsWithinDist2D(ArenaCenter, SafeRadius)) 
			return false;

		if (bHackShrinkSafeSpace)
		{
			// We're inside safe bounds, but might have gotten stuck below the stairs for some reason	
			FVector StairsCenter = ArenaCenter - Arena.ActorRightVector * 2200.0;
			if (Owner.ActorLocation.IsWithinDist2D(StairsCenter, 1500.0))
			{
				// We're in the stairs space and above arena floor, check if below stairs
				float StairsHeight = Math::GetMappedRangeValueClamped(FVector2D(1150.0, 1500.0), FVector2D(180.0, 20.0), Owner.ActorLocation.Dist2D(StairsCenter));
				if (Owner.ActorLocation.Z < ArenaCenter.Z + StairsHeight)
					return false;
			}
		}

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
		HealthComp.TakeDamage(HealthComp.MaxHealth, EDamageType::Default, Game::Zoe.HasControl() ? Game::Zoe : Game::Mio);
	}

	bool ShouldHackShrinkSafeSpace() const
	{
		if (GeckoComp.Team == nullptr)
			return false;
		if (AnimComp.FeatureTag == FeatureTagGecko::GrabbedByWhip)
			return false; // Held by whip, don't die until thrown even if held outside arena	
		if (Time::GetGameTimeSince(GeckoComp.Team.LastMemberJoinedTime) < 20.0)
			return false; // We're still at the start of scenario
		if (Time::GetGameTimeSince(GeckoComp.Team.LastAttackTime) < 8.0)
			return false; // Some gecko started an attack recently so were not stuck
		// Sus! Kill any gecko more than just outside arena
		return true; 
	}

	void DebugDrawSafeBounds() const
	{
		FVector ArenaCenter = Arena.ArenaCenter.ActorLocation;
		Debug::DrawDebugCylinder(ArenaCenter + FVector(0,0,-20), ArenaCenter + FVector(0,0,600.0), 1800, 20, FLinearColor::DPink, 10);
		FVector StairsLoc = ArenaCenter - Arena.ActorRightVector * 2200.0;
		Debug::DrawDebugCylinder(StairsLoc + FVector(0,0,-20), StairsLoc + FVector(0,0,20.0), 1500, 40, FLinearColor::Green, 10);
		Debug::DrawDebugCylinder(StairsLoc + FVector(0,0,-20), StairsLoc + FVector(0,0,180.0), 1150, 40, FLinearColor::LucBlue, 10);
		FVector LineDir = (Arena.ActorForwardVector + Arena.ActorRightVector * 0.7).GetSafeNormal2D();
		Debug::DrawDebugLine(StairsLoc + LineDir * 1150 + FVector(0,0,180), StairsLoc + LineDir * 1500 + FVector(0,0,20), FLinearColor::Yellow, 10);
	}
};