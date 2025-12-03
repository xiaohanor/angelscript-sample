

UCLASS(HideCategories = "Debug Activation Collision Cooking Rendering Actor Tags DataLayers")
class ASoftSplitAudioManager : AHazeActor
{
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_LastDemotable;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComponent;

	private UHazeAudioComponentManager AudioComponentManager;
	private ASoftSplitManager SplitManager;

	private FHazeAudioID Rtpc_Distance_Scifi_Fantasy = FHazeAudioID("Rtpc_Meltdown_Distance_Scifi_Fantasy");
	// We use specific emitter rtpcs so we can reuse the same rtpcs both for fantasy and scifi
	private FHazeAudioID Rtpc_Panning_Scifi_Fantasy_X = FHazeAudioID("Rtpc_Meltdown_Panning_Scifi_Fantasy_X");
	private FHazeAudioID Rtpc_Panning_Scifi_Fantasy_Y = FHazeAudioID("Rtpc_Meltdown_Panning_Scifi_Fantasy_Y");

	private TArray<USoftSplitAudioSpotSoundComponent> Components;
	private UHazeAudioEmitter MusicEmitter;

	void Add(USoftSplitAudioSpotSoundComponent Component)
	{
		Components.Add(Component);
	}

	void Remove(USoftSplitAudioSpotSoundComponent Component)
	{
		Components.RemoveSingleSwap(Component);
	} 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AudioComponentManager = UHazeAudioComponentManager::Get();
		SplitManager = ASoftSplitManager::GetSoftSplitManger();
		MusicEmitter = Music::Get().Emitter;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// If this manager exists in another level layer, wait for it.
		if (SplitManager == nullptr)
			SplitManager = ASoftSplitManager::GetSoftSplitManger();

		if (SplitManager == nullptr)
		{
			return;
		}

		auto Players = Game::Players;
		auto PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Players[0]);
		
		FVector PlaneOrigin;
		FVector PlaneNormal;
		SplitManager.GetWorldSplitPlane(EHazeWorldLinkLevel::Fantasy, PlaneOrigin, PlaneNormal);

		float ScreenDirection_X = 0;
		float ScreenDirection_Y = 0;
		// Only checks one camera now, but both should be the same in *this* level.
		switch(PerspectiveModeComp.PerspectiveMode)
		{
			case EPlayerMovementPerspectiveMode::SideScroller:
			ScreenDirection_Y = 0;
			ScreenDirection_X = Math::Clamp(SplitManager.DirectionInScreenSpace.X, -1, 1);
			break;
			case EPlayerMovementPerspectiveMode::TopDown:
			default:
				ScreenDirection_X = Math::Clamp(SplitManager.DirectionInScreenSpace.X, -1, 1);
				ScreenDirection_Y = Math::Clamp(SplitManager.DirectionInScreenSpace.Y, -1, 1);
			break;
		}

		if (MusicEmitter != nullptr)
		{
			MusicEmitter.SetRTPC(Rtpc_Panning_Scifi_Fantasy_X, ScreenDirection_X, 0);
			MusicEmitter.SetRTPC(Rtpc_Panning_Scifi_Fantasy_Y, -ScreenDirection_Y, 0);
		}

		for (auto SoftSplitComponent : Components)
		{
			if (SoftSplitComponent == nullptr)
				continue;

			auto Component = SoftSplitComponent.GetAudioComponentBasedOnAttachment();

			if (Component == nullptr)
				continue;

			if (!Component.IsPlaying())
				continue;
			
			auto ComponentLocation = Component.WorldLocation;
			// Where is the component attached or located.
			auto WorldLinkLevel = SplitManager.GetSplitForLocation(ComponentLocation);

			const auto& MultiPositions = Component.GetMultipleSoundPositions();
			if (MultiPositions.Num() > 0 && MultiPositions.Num() == 2)
			{
				// Get the closest players position based on world level.
				// Mio is scifi, Zoe fantasy.
				ComponentLocation = MultiPositions[WorldLinkLevel == EHazeWorldLinkLevel::SciFi ? 0 : 1].GetPosition();
			}

			if (Component.MaxAttenuationRadiusPlaying == 0)
			{
				if (WorldLinkLevel == EHazeWorldLinkLevel::SciFi)
				{
					Component.SetRTPCOnEmitters(Rtpc_Panning_Scifi_Fantasy_X, -ScreenDirection_X);
					Component.SetRTPCOnEmitters(Rtpc_Panning_Scifi_Fantasy_Y, ScreenDirection_Y);
				}
				else
				{
					Component.SetRTPCOnEmitters(Rtpc_Panning_Scifi_Fantasy_X, ScreenDirection_X);
					Component.SetRTPCOnEmitters(Rtpc_Panning_Scifi_Fantasy_Y, -ScreenDirection_Y);
				}

				continue;
			}

			float MaxAttenuation = Component.MaxAttenuationRadiusPlaying;
			
			auto WorldPlaneOrigin = PlaneOrigin;
			auto WorldPlaneNormal = PlaneNormal;
			if (WorldLinkLevel == EHazeWorldLinkLevel::SciFi)
			{
				WorldPlaneOrigin = SplitManager.Position_FantasyToScifi(WorldPlaneOrigin);
				WorldPlaneNormal = -WorldPlaneNormal;
			}

			FVector Position = Math::ClosestPointOnInfiniteLine(
				ComponentLocation, ComponentLocation + WorldPlaneNormal, 
				WorldPlaneOrigin);

#if TEST
			if (AudioDebug::IsEnabled(EDebugAudioWorldVisualization::Gameplay))
			{
				Debug::DrawDebugPoint(Position, 50, FLinearColor::Blue);
				Debug::DrawDebugPoint(ComponentLocation, 50, FLinearColor::Green);
			}
#endif
			float DistanceValue = 0.5;
			FVector2D ScreenPos; 
			auto InWorld = 
				SplitManager.GetVisibleSoftSplitAtLocationAndScreenPosition(ComponentLocation, ScreenPos);

			float Radius = SoftSplitComponent.Radius;
			
			// If not in the same world, check the distance to the split
			if (InWorld != WorldLinkLevel)
			{
				DistanceValue = Math::Clamp(
					Math::Max(Position.Distance(ComponentLocation) / Radius, 0),
				 0, 1);
			}
			// If the same check the screen space instead.
			else
			{
				auto AbsMax = ScreenPos.AbsMax;
				DistanceValue = Math::Clamp((AbsMax - 1), 0, 1);
			}
			
			Component.SetRTPCOnEmitters(Rtpc_Distance_Scifi_Fantasy, DistanceValue);
		}
	}
}