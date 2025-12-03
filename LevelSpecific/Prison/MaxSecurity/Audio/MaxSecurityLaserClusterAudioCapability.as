class UMaxSecurityLaserClusterAudioCapability : UHazeCapability
{
	TArray<int32> CurrentLasersCountByCluster;
	default CurrentLasersCountByCluster.SetNum(4);

	TArray<int32> LastLasersCountByCluster;
	default LastLasersCountByCluster.SetNum(4);

	UMaxSecurityLaserClusterAudioDataComponent AudioDataComp;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Drone::GetSwarmDronePlayer();
		AudioDataComp = UMaxSecurityLaserClusterAudioDataComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	void ResetCurrent()
	{
		for(int i=0; i < 4; ++i)
			CurrentLasersCountByCluster[i] = 0;
	}

	void CacheCurrentAndSendEvents()
	{
		for(int i=0; i < 4; ++i)
		{
			if (LastLasersCountByCluster[i] != CurrentLasersCountByCluster[i])
			{
				auto Params = FMaxSecurityLaserClusterChangeParams(i, CurrentLasersCountByCluster[i], LastLasersCountByCluster[i]);
				UMaxSecurityLaserClusterEventHandler::Trigger_OnLaserClusterChange(Owner,  Params);
			}

			LastLasersCountByCluster[i] = CurrentLasersCountByCluster[i];
			if (IsDebugActive())
				PrintToScreen("LastLasersCountByCluster["+i+"]  " + LastLasersCountByCluster[i]);
		}
	}

	// We have four clusters
	// _| |_
	// ¨| |¨
	// Count how many we have in each cluster based on dot.
	// Push events only when changed
	// NOTE: One laser may be in multiple clusters!

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto ViewForward = Player.ViewRotation.ForwardVector;
		ViewForward.Z = 0;
		ViewForward.Normalize();
#if TEST
		bool bDebug = AudioDebug::IsEnabled(EDebugAudioWorldVisualization::Gameplay);
		if (bDebug)
		{
			//PrintToScreen("INTERACTIONS: " + AudioDataComp.LaserInteractions.Num());
			PrintToScreen("ViewForward: " + ViewForward);
			Debug::DrawDebugArrow(Player.ActorLocation, Player.ActorLocation + ViewForward * 200, 50, FLinearColor::Green);
		}
#endif
		ResetCurrent();


		for (auto InteractionPoint : AudioDataComp.LaserInteractions)
		{
			auto DirectionFromPlayer = InteractionPoint - Player.ActorLocation;

#if TEST
			if (bDebug)
				Debug::DrawDebugArrow(Player.ActorLocation, Player.ActorLocation + DirectionFromPlayer * 200, 50, FLinearColor::Green);
#endif

			DirectionFromPlayer.Z = 0;
			DirectionFromPlayer.Normalize();

			auto Dot = ViewForward.DotProduct(DirectionFromPlayer);
			auto Cross = ViewForward.CrossProduct(DirectionFromPlayer);

			// 0 == Left
			// 1 == Right
			int32 Index = Cross.Z > 0 ? 1 : 0;
			// Behind the drone/camera
			if (Dot < 0)
			{
				// 2 == Left Back
				// 3 == Right back
				Index += 2;
			}
			CurrentLasersCountByCluster[Index]++;
#if TEST
			if (bDebug)
				Debug::DrawDebugPoint(InteractionPoint, 40, FLinearColor::Green);
#endif
		}

		CacheCurrentAndSendEvents();

	}
}