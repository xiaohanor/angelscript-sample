class ASkylineDaClubAudioLevelScriptActor : AAudioLevelScriptActor
{
	FHazeAudioID VIPRoomMusicDuckingRTPC = FHazeAudioID("Rtpc_Music_Skyline_DaClub_VIPRoom_Music_Ducker");
	float DuckingRTPCValue = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		AudioComponent::SetGlobalRTPC(VIPRoomMusicDuckingRTPC, 0.0);
	}

	UFUNCTION(BlueprintCallable)
	void SetVIPRoomMusicDucking(ASplineActor CorridorSpline)
	{
		if(CorridorSpline == nullptr)
			return;

		float MinAlpha = MAX_flt;
		for(auto Player : Game::GetPlayers())
		{
			const float PlayerSplineAlpha = CorridorSpline.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation)
			 								/ CorridorSpline.Spline.SplineLength;

			MinAlpha = Math::Min(MinAlpha, PlayerSplineAlpha);
		}

		if(MinAlpha != DuckingRTPCValue)
		{
			DuckingRTPCValue = MinAlpha;
			AudioComponent::SetGlobalRTPC(VIPRoomMusicDuckingRTPC, DuckingRTPCValue);
		}
	}	
}