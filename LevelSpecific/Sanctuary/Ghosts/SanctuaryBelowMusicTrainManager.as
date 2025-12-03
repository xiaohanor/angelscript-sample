struct FHazeSanctuaryBelowMusicData
{
	int BusIndex = 0;
	int VolumeCount = 0;
	TArray<ASanctuaryGhostSpline> GhostActors;
	UHazeProxyAudioEmitter ProxyEmitter;
	TArray<FAkSoundPosition> SoundPositions;
#if TEST
	FLinearColor Color = FLinearColor::MakeRandomColor();
#endif
}

// It is, a great name.
class ASanctuaryBelowMusicTrainManager : AHazeActor
{
	private TArray<FHazeSanctuaryBelowMusicData> GhostDatas;
	private TArray<UHazeAudioListenerComponentBase> Listeners;
	private TArray<UHazeProxyAudioEmitter> ProxyEmitters;

	private UHazeAudioEmitter MusicEmitter;
	private const int BUS_COUNT = 3;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GhostDatas.SetNum(BUS_COUNT);

		auto GhostActors = TListedActors<ASanctuaryGhostSpline>().GetArray();
		for (auto GhostActor: GhostActors)
		{
			// Random is fun.
			auto GroupIndex = Math::RandRange(0, BUS_COUNT - 1);
			GhostDatas[GroupIndex].GhostActors.Add(GhostActor);
			GhostDatas[GroupIndex].VolumeCount += GhostActor.SplineVolumes.Num();
		}
		
		for (int i=0; i < BUS_COUNT; ++i)
		{
			auto& Data = GhostDatas[i];

			Data.SoundPositions.SetNum(Data.VolumeCount * 2); // 2 Listeners
		}

		MusicEmitter = UHazeAudioMusicManager::Get().Emitter;
		Audio::GetListeners(this, Listeners);
	}

	bool IsInactive()
	{
		if (MusicEmitter != nullptr && MusicEmitter.HasProxy())
			return false;

		return true;
	}

	void Start()
	{
		ProxyEmitters = MusicEmitter.GetProxyListenerEmitters();

		// We know the order:ish (doesn't matter) of the proxies, at least the 4th (last) we wanna skip.
		for (int i=0; i < ProxyEmitters.Num() && i < BUS_COUNT; ++i)
		{
			auto& Data = GhostDatas[i];
			Data.ProxyEmitter = ProxyEmitters[i];
		}
	}

	void Stop() 
	{
		if (ProxyEmitters.Num() == 0)
			return;
		
		ProxyEmitters.Reset();

		for (int BusIndex=0; BusIndex < BUS_COUNT; ++BusIndex)
		{
			auto& Data = GhostDatas[BusIndex];
			Data.ProxyEmitter = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Only tick when the proxies are active.
		if (IsInactive())
		{
			Stop();
			return;
		}

		bool bTeleport = false;
		if (ProxyEmitters.Num() == 0)
		{
			Start();
			bTeleport = true;
		}

		UpdateComponentPositions(DeltaSeconds, bTeleport);
	}

	void UpdateComponentPositions(float DeltaSeconds, bool bTeleport)
	{
		if (GhostDatas.Num() == 0)
			return;
		
		FVector Front,Back;
		for (int BusIndex=0; BusIndex < BUS_COUNT; ++BusIndex)
		{
			auto& Data = GhostDatas[BusIndex];

			int SoundPositionIndex = 0;
			for (int GhostIndex=0; GhostIndex < Data.GhostActors.Num(); ++GhostIndex)
			{
				auto GhostActor = Data.GhostActors[GhostIndex];

				for (int i=0; i < GhostActor.SplineVolumes.Num(); ++i)
				{
					const auto& Volume = GhostActor.SplineVolumes[i];
					Volume.GetFrontAndBackLocations(Front, Back);

					auto MaxRadius = Math::Max(
						(Volume.Width.Y - Volume.Width.X) * Volume.BaseWidth, 
						(Volume.Height.Y - Volume.Height.X) * Volume.BaseWidth
						) / 2;
					
					#if TEST
					if (AudioDebug::IsEnabled(EDebugAudioViewportVisualization::Music))
					{
						Debug::DrawDebugCylinder(Front, Back, MaxRadius, LineColor = Data.Color);

						FString ProxyName = f"Choir {BusIndex}";
						if (Data.ProxyEmitter != nullptr)
							ProxyName = Data.ProxyEmitter.Name.ToString();

						Debug::DrawDebugString(Front, ProxyName, Data.Color);
					}
					#endif

					for (int ListenerIndex = 0; ListenerIndex < Listeners.Num(); ListenerIndex++)
					{
						auto ListenerPosition = Listeners[ListenerIndex].GetWorldLocation();
						auto ClosestPoint = Math::ClosestPointOnLine(Front, Back, ListenerPosition);

						auto Direction = ListenerPosition - ClosestPoint;
						Direction.Normalize();
						
						ClosestPoint += Direction * MaxRadius;
						auto PreviousPosition = Data.SoundPositions[SoundPositionIndex].GetPosition();
						auto NewPosition = ClosestPoint;
						
						// Teleport if just initialized.
						if (!bTeleport)
							NewPosition = PreviousPosition.MoveTowards(ClosestPoint, 1500 * DeltaSeconds);
						
						Data.SoundPositions[SoundPositionIndex].SetPosition(NewPosition);
						++SoundPositionIndex;

						#if TEST
						if (AudioDebug::IsEnabled(EDebugAudioViewportVisualization::Music))
						{
							Debug::DrawDebugPoint(NewPosition, 20, Data.Color);
						}
						#endif
					}
				}
			}

			if (Data.ProxyEmitter != nullptr)
				Data.ProxyEmitter.SetMultipleSoundPositions(Data.SoundPositions);
		}
	}
}