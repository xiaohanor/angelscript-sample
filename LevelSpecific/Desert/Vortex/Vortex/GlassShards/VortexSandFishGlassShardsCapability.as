struct FVortexSandFishGlassShardsActivateParams
{
	bool bTargetIsMio;
	float FlyToHeight;
}

struct FVortexSandFishGlassShardsDeactivateParams
{
	bool bSuccess;
}

class UVortexSandFishGlassShardsCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AVortexSandFish SandFish;
	UVortexSandFishGlassShardsComponent GlassShardsComp;

	int SpawnedGlassShards = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandFish = Cast<AVortexSandFish>(Owner);
		GlassShardsComp = UVortexSandFishGlassShardsComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FVortexSandFishGlassShardsActivateParams& Params) const
	{
		if(!GlassShardsComp.bIsActive)
			return false;

		Params.bTargetIsMio = Math::RandBool();
		Params.FlyToHeight = Math::RandRange(1500, 3500);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FVortexSandFishGlassShardsDeactivateParams& Params) const
	{
		if(!GlassShardsComp.bIsActive)
			return true;

		if(SpawnedGlassShards >= GlassShardsComp.CurrentVolley.NumGlassShards)
		{
			Params.bSuccess = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FVortexSandFishGlassShardsActivateParams Params)
	{
		SpawnedGlassShards = 0;
		SpawnGlassShard(Params.bTargetIsMio, Params.FlyToHeight);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FVortexSandFishGlassShardsDeactivateParams Params)
	{
		GlassShardsComp.StopFiringGlassShards(Params.bSuccess);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			int TargetSpawnedCount = Math::RoundToInt(ActiveDuration / GlassShardsComp.CurrentVolley.Interval);
			TargetSpawnedCount = Math::Min(TargetSpawnedCount, GlassShardsComp.CurrentVolley.NumGlassShards);

			for(; SpawnedGlassShards < TargetSpawnedCount; SpawnedGlassShards++)
			{
				CrumbSpawnGlassShard(Math::RandBool(), Math::RandRange(1500, 3500));
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSpawnGlassShard(bool bTargetIsMio, float FlyToHeight)
	{
		SpawnGlassShard(bTargetIsMio, FlyToHeight);
	}

	private void SpawnGlassShard(bool bTargetIsMio, float FlyToHeight)
	{
		AVortexSandFishGlassShard GlassShard = SpawnActor(GlassShardsComp.GlassShardClass, SandFish.ActorLocation, FRotator::ZeroRotator, NAME_None, true);
		GlassShard.MakeNetworked(this, GlassShardsComp.TotalSpawnedGlassShards);
		GlassShardsComp.TotalSpawnedGlassShards += 1;

		GlassShard.TargetPlayer = bTargetIsMio ? Game::Mio : Game::Zoe;
		GlassShard.FlyToHeight = FlyToHeight;

		FinishSpawningActor(GlassShard);
	}
};