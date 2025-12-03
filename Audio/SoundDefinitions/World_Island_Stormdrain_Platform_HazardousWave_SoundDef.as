
UCLASS(Abstract)
class UWorld_Island_Stormdrain_Platform_HazardousWave_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnWaveReachEnd(){}

	UFUNCTION(BlueprintEvent)
	void OnWaveStartMoving(){}

	UFUNCTION(BlueprintEvent)
	void OnWaveImpactPlatform(FHazardousWavePlatformImpactParams ImpactParams){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotEditable)
	UHazeAudioEmitter RailEmitter;

	UPROPERTY(NotEditable)
	UHazeAudioEmitter WaveEmitter;

	UStaticMeshComponent RailMesh;
	UPrimitiveComponent WaveMesh;

	AIslandStormdrainHazardousWave HazardousWave;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		RailMesh = Cast<UStaticMeshComponent>(RailEmitter.AudioComponent.AttachParent);
		WaveMesh = Cast<UPrimitiveComponent>(WaveEmitter.AudioComponent.AttachParent);

		HazardousWave = Cast<AIslandStormdrainHazardousWave>(HazeOwner);

		RailEmitter.AudioComponent.GetZoneOcclusion(true, bAutoSetRtpc = true);
		WaveEmitter.AudioComponent.GetZoneOcclusion(true, bAutoSetRtpc = true);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return HazardousWave.bWaveActive;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !HazardousWave.bWaveActive;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		SetEmitterPositions();
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Get Wave Alpha"))
	float GetWaveAlpha()
	{
		return HazardousWave.GetMovementAlpha();
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Get Rail Occlusion Value"))
	float GetRailOcclusionValue()
	{
		return RailEmitter.AudioComponent.GetZoneOcclusion(true, bAutoSetRtpc = true);
	}

	void SetEmitterPositions()
	{
		auto Players = Game::GetPlayers();
		TArray<FAkSoundPosition> RailPositions;
		TArray<FAkSoundPosition> WavePositions;

		for(auto& Player : Players)
		{
			//Rail
			{
				FVector ClosestPos;
				const float Dist = RailMesh.GetClosestPointOnCollision(Player.ActorCenterLocation, ClosestPos);
				if(Dist < 0)
					ClosestPos = RailMesh.WorldLocation;
				
				RailPositions.Add(FAkSoundPosition(ClosestPos));				
			}
			//Wave
			{			
				FVector ClosestPos = WaveMesh.Bounds.GetBox().GetClosestPointTo(Player.ActorCenterLocation);
				WavePositions.Add(FAkSoundPosition(ClosestPos));				
			}
		}

		RailEmitter.AudioComponent.SetMultipleSoundPositions(RailPositions);
		WaveEmitter.AudioComponent.SetMultipleSoundPositions(WavePositions);

		#if TEST
		if (IsDebugging())
		{
			for(auto& Pos : RailPositions)
			{
				Debug::DrawDebugPoint(Pos.Position, 25.f, FLinearColor::Blue, bDrawInForeground = true);
			}
		}
		#endif
	}
}