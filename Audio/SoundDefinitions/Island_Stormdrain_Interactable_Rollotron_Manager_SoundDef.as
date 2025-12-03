
UCLASS(Abstract)
class UIsland_Stormdrain_Interactable_Rollotron_Manager_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnRollotronDetonate(FRollotronEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnRollotronSpikesOut(FRollotronEventParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY()
	UHazeAudioEmitter WaveMultiEmitter;

	UPROPERTY(BlueprintReadOnly)
	float AttenuationDistance = 8000;

	AAIIslandRollotronAudioManagerActor Manager;
	const float SINGLE_ROLLATRON_MAX_SPEED_RANGE = 400.0;

	int GetNumberOfRollatrons() const property
	{
		return Manager.Rollotrons.Num();
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Manager = Cast<AAIIslandRollotronAudioManagerActor>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		TArray<FAkSoundPosition> SoundPositions;
		
		for(auto Rollotron : Manager.Rollotrons)
		{
			SoundPositions.Add(FAkSoundPosition(Rollotron.GetActorLocation()));
		}

		WaveMultiEmitter.AudioComponent.SetMultipleSoundPositions(SoundPositions, AkMultiPositionType::MultiSources);
	}

	UFUNCTION()
	void OnWaveSpawned()
	{
		OnSpawnWave();
	}

	UFUNCTION(BlueprintEvent)
	void OnSpawnWave() {}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Average Rollotron Velocity"))
	float GetAverageVelocity() 
	{		
		if(NumberOfRollatrons == 0)
			return 0.0;

		float AccuSpeed = 0.0;
		int NumMovingRollotrons = 0;

		for(auto Rollotron : Manager.Rollotrons)
		{	
			const float NormalizedSpeed = Rollotron.CachedSpeed / SINGLE_ROLLATRON_MAX_SPEED_RANGE;

			if(NormalizedSpeed < 0.1)
				continue;

			const float DistSqrd = GetRollotronClosestPlayerDistanceSqrd(Rollotron);
			if(DistSqrd > Math::Square(AttenuationDistance))
				continue;

			if(NormalizedSpeed > 0.1)
			{
				AccuSpeed += NormalizedSpeed;
				NumMovingRollotrons++;
			}
		}

		if(NumMovingRollotrons == 0)
			return 0.0;

		return Math::Clamp(AccuSpeed / NumMovingRollotrons, 0.0, 1.0);
	}

	float GetRollotronClosestPlayerDistanceSqrd(AAIIslandRollotron Rollotron)
	{
		float ClosestDistSqrd = BIG_NUMBER;
		for(auto Player : Game::GetPlayers())
		{
			const float PlayerDistSqrd = Player.GetSquaredDistanceTo(Rollotron);
			if(PlayerDistSqrd < ClosestDistSqrd)
			{
				ClosestDistSqrd = PlayerDistSqrd;
			}
		}

		return ClosestDistSqrd;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Number of Rollotrons"))
	float GetNumSpawnedRollotrons()
	{
		return NumberOfRollatrons;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Cluster Alpha"))
	float GetClusterAlphaValue()
	{
		float AccuAlpha = 1.0;
		float RangeSqrd = Math::Square(AttenuationDistance);

		for(auto Rollotron : Manager.Rollotrons)
		{
			const float NormalizedDistSqrd = Math::Min(GetRollotronClosestPlayerDistanceSqrd(Rollotron) / RangeSqrd, 1);
			AccuAlpha += (1 - NormalizedDistSqrd);
		}

		return Math::Min(AccuAlpha, 6);
	}

}