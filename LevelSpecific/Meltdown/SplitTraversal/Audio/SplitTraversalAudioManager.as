

UCLASS(HideCategories = "Debug Activation Collision Cooking Rendering Actor Tags DataLayers")
class ASplitTraversalAudioManager : AHazeActor
{
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_LastDemotable;

	UPROPERTY(EditInstanceOnly)
	float AttenuationDistance = 10000;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComponent;

	private UHazeAudioComponentManager AudioComponentManager;
	private ASplitTraversalManager SplitManager;

	private FHazeAudioID Rtpc_Distance_Scifi_Fantasy = FHazeAudioID("Rtpc_Meltdown_Distance_Scifi_Fantasy");

	private TArray<EHazeWorldLinkLevel> PlayerToLevel;
	default PlayerToLevel.Add(EHazeWorldLinkLevel::SciFi);
	default PlayerToLevel.Add(EHazeWorldLinkLevel::Fantasy);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AudioComponentManager = UHazeAudioComponentManager::Get();
		SplitManager = ASplitTraversalManager::GetSplitTraversalManager();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// If this manager is added to any other level
		if (SplitManager == nullptr)
		{
			SplitManager = ASplitTraversalManager::GetSplitTraversalManager();
		}

		if (SplitManager == nullptr)
			return;
		
		auto Players = Game::Players;
		for (int i=0; i<2; ++i)			
		{
			PlayerToLevel[i] = SplitManager.GetSplitForLocation(Players[i].ActorCenterLocation);
		}
		bool bUseAsNormalDistanceRtpc = PlayerToLevel[0] == PlayerToLevel[1];

		for (auto Component : AudioComponentManager.AudioComponents)
		{
			if (!Component.IsPlaying())
				continue;

			if (Component.IsPlayerAudioComp())
				continue;

			if (Cast<AHazePlayerCharacter>(Component.GetAttachmentRootActor()) != nullptr)
				continue;

			float MaxAttenuation = Component.MaxAttenuationRadiusPlaying;
			if (Component.MaxAttenuationRadiusPlaying == 0)
				MaxAttenuation = AttenuationDistance;

			auto WorldLinkLevel = SplitManager.GetSplitForLocation(Component.WorldLocation);

			float RtpcValue = bUseAsNormalDistanceRtpc ? 1 : 0;

			for (int i=0; i<2; ++i)
			{
				auto ComponentPosition = Component.WorldLocation;

				if (PlayerToLevel[i] != WorldLinkLevel)
				{
					EHazeWorldLinkLevel TargetLevel = PlayerToLevel[i];

					ComponentPosition = SplitManager.Position_Convert(
						ComponentPosition,
						WorldLinkLevel, 
						TargetLevel
						);
				}

				auto Distance = Players[i].ActorLocation.Distance(ComponentPosition);

				if (!bUseAsNormalDistanceRtpc)
				{
					RtpcValue += (1 - Math::Clamp(Distance/MaxAttenuation, 0, 1)) * (int(EHazeWorldLinkLevel::SciFi)-i == int(WorldLinkLevel) ? 1 : -1);
				}
				else
				{
					RtpcValue = Math::Min(Distance/MaxAttenuation, RtpcValue);
				}
			}
			
			Component.SetRTPCOnEmitters(Rtpc_Distance_Scifi_Fantasy, Math::Clamp(RtpcValue, 0, 1));
		}
	}
}