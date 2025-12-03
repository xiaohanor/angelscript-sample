struct FMeltdownBossCubeGridAudioData
{
	AMeltdownBossCubeGrid CubeGrid;
	FVector CubeTopLocation;
	bool bIsMoving = false;

	FMeltdownBossCubeGridAudioData(AMeltdownBossCubeGrid _CubeGrid, bool _bIsMoving)
	{
		CubeGrid = _CubeGrid;
		bIsMoving = _bIsMoving;

		FVector CubeTop = CubeGrid.InstancedMesh.WorldLocation;
		CubeTop.Z += CubeGrid.InstancedMesh.BoundsRadius / 4;
		CubeTop.X += CubeGrid.InstancedMesh.BoundsRadius / 2.5;
		CubeTop.Y += CubeGrid.InstancedMesh.BoundsRadius / 2.5;

		CubeTopLocation = CubeTop;
	}

	int opCmp(FMeltdownBossCubeGridAudioData Other) const
	{
		return GetClosestPlayerDistanceSqrd() > Other.GetClosestPlayerDistanceSqrd() ? 1 : -1;
	}

	float GetClosestPlayerDistanceSqrd() const
	{
		float ClosestDistSqrd = MAX_flt;
		for(auto Player : Game::Players)
		{
			const float PlayerDistSqrd = Player.ActorLocation.DistSquared(CubeTopLocation);
			ClosestDistSqrd = Math::Min(ClosestDistSqrd, PlayerDistSqrd);
		}

		return ClosestDistSqrd;
	}
}


UCLASS(Abstract)
class UCharacter_Boss_Meltdown_MeltdownBoss_MeltdownBossCubeGrid_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	AMeltdownBoss MeltdownBoss;
	TArray<AMeltdownBossCubeGrid> CubeGrids;
	TArray<FMeltdownBossCubeGridAudioData> PoppedUpCubesDatas;

	UPROPERTY(BlueprintReadOnly)
	const int NumPooledCubeEmitters = 8;

	UPROPERTY(BlueprintReadOnly)
	FHazeAudioEmitterRotationPool CubeEmitterPool;
	UFUNCTION(BlueprintEvent)
	void InitCubePoolEmitters(UHazeAudioEmitter Emitter) {}

	UFUNCTION(BlueprintEvent)
	void UpdateCube(UHazeAudioEmitter CubeEmitter, const bool bIsMoving) {};

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		MeltdownBoss = Cast<AMeltdownBoss>(HazeOwner);
		CubeEmitterPool = GetPooledEmitters(NumPooledCubeEmitters, FOnInitRotationPoolComponent(this, n"InitCubePoolEmitters"));
		CubeGrids = TListedActors<AMeltdownBossCubeGrid>().GetArray();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const int NumCubeGrids = CubeGrids.Num();
		if(NumCubeGrids == 0)
			return;

		PoppedUpCubesDatas.Empty();
		for(auto& CubeGrid : CubeGrids)
		{
			for(auto& DisplaceComp : CubeGrid.DisplacementComponents)
			{
				if(DisplaceComp.bModifyCubeGridCollision)
				{			
					const bool bNeedsUpdate = CubeGrid.bCubeStartedMoving || CubeGrid.bCubeStoppedMoving;				
					if(bNeedsUpdate)
					{					
						bool bIsMoving = false;				
						if(CubeGrid.bCubeStartedMoving)
						{
							CubeGrid.bCubeStartedMoving = false;
							bIsMoving = true;
						}
						else
						{
							CubeGrid.bCubeStoppedMoving = false;
						}

						PoppedUpCubesDatas.Add(FMeltdownBossCubeGridAudioData(CubeGrid, bIsMoving));
						CubeGrid.bCubeStartedMoving = false;		
						break;
					}
				}
			}
		}

		// Sorting function overriden, sort by distance to closest player
		PoppedUpCubesDatas.Sort();
		const int CubeIterationRange = Math::Min(PoppedUpCubesDatas.Num(), NumPooledCubeEmitters);

		for(int i = 0; i < CubeIterationRange; ++i)
		{
			auto CubeData = PoppedUpCubesDatas[i];
			UHazeAudioEmitter CubeEmitter;
			int _;
			AudioEmitterRotationPool::GetNext(CubeEmitterPool, CubeEmitter, _, CubeData.CubeTopLocation, true);
			UpdateCube(CubeEmitter, CubeData.bIsMoving);
		}
	}
}