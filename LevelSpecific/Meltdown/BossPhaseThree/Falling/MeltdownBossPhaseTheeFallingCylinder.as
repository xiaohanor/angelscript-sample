enum EMeltdownPhaseThreeFallingWorld
{
	Skyline,
	Summit,
	Island,
	Tundra,
	OilRig,
	Prison,
	pigworld, 
	kitetown,
	solarflare,
	battlefield,
	MAX UMETA(Hidden)
};

class AMeltdownBossPhaseTheeFallingCylinder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Cylinder;

	UPROPERTY(DefaultComponent)
	UBoxComponent StartTrigger;

	UPROPERTY(DefaultComponent)
	UBoxComponent PlayerTrigger;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComponent;

	UPROPERTY(EditAnywhere)
	int VideoIndex = 0;
	
	UPROPERTY(EditDefaultsOnly, Meta = (ArraySizeEnum = "/Script/Angelscript.EMeltdownPhaseThreeFallingWorld"))
	TArray<FString> Movies;
	default Movies.SetNum(EMeltdownPhaseThreeFallingWorld::MAX);

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface Material;

	UPROPERTY(VisibleAnywhere)
	UBinkMediaPlayer CurrentPlayer;
	UPROPERTY(VisibleAnywhere)
	UBinkMediaTexture CurrentTexture;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface PostProcessMaterial;

	bool bStarted = false;
	bool bDisabled = false;
	int StencilValue;

	UPROPERTY(VisibleAnywhere)
	UMaterialInstanceDynamic DynamicMaterial;
	UPROPERTY(VisibleAnywhere)
	UMaterialInstanceDynamic DynamicPostProcessMaterial;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlapStartTrigger");
		PlayerTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlapStopTrigger");

		Cylinder.SetCustomDepthStencilValue(100);
		Cylinder.SetRenderCustomDepth(true);
		Cylinder.MarkRenderStateDirty();
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		Cylinder.SetCustomDepthStencilValue(100);
		Cylinder.SetRenderCustomDepth(true);
		Cylinder.MarkRenderStateDirty();
	}
#endif

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		auto PostProcessComp = UPostProcessingComponent::Get(Game::Mio);
		PostProcessComp.PostProcessMaterial.Clear(this);
	}

	void Start()
	{
		if (bStarted)
			return;

		bStarted = true;

		if (CurrentPlayer == nullptr)
		{
			CurrentPlayer = NewObject(nullptr, UBinkMediaPlayer);
			CurrentTexture = NewObject(nullptr, UBinkMediaTexture);

			CurrentTexture.SetMediaPlayer(CurrentPlayer);

			DynamicMaterial = Material::CreateDynamicMaterialInstance(this, Material);
			DynamicMaterial.SetTextureParameterValue(n"VideoInput", CurrentTexture);
			Cylinder.SetMaterial(0, DynamicMaterial);
			Cylinder.SetCustomDepthStencilValue(StencilValue);

			switch (StencilValue)
			{
				case 1: DynamicPostProcessMaterial.SetTextureParameterValue(n"VideoTexture1", CurrentTexture); break;
				case 2: DynamicPostProcessMaterial.SetTextureParameterValue(n"VideoTexture2", CurrentTexture); break;
				case 3: DynamicPostProcessMaterial.SetTextureParameterValue(n"VideoTexture3", CurrentTexture); break;
			}
		}

		int VideoSlot = Math::WrapIndex(VideoIndex, 0, Movies.Num());
		CurrentPlayer.OpenUrl(Movies[VideoSlot]);
	}

	void Stop()
	{
		if (!bStarted)
			return;

		bStarted = false;
		CurrentPlayer.Stop();
		CurrentTexture = nullptr;
		CurrentPlayer = nullptr;
		DynamicMaterial = nullptr;
		Cylinder.SetMaterial(0, nullptr);
	}

	UFUNCTION()
	void Disable()
	{
		bDisabled = true;

		auto Manager = UMeltdownBossPhaseFallingVideoManager::GetOrCreate(Game::Mio);
		Manager.StopPlaying(this);

		auto PostProcessComp = UPostProcessingComponent::Get(Game::Mio);
		PostProcessComp.PostProcessMaterial.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bDisabled)
			return;

		auto SkydiveComp = UMeltdownSkydiveComponent::Get(Game::Mio);
		if (SkydiveComp.bSkydiveOver)
		{
			Disable();
			return;
		}

		if (bStarted)
		{
			PrintToScreen(f"Playing Video {VideoIndex}");
		}

		// auto SkydiveSettings = UMeltdownSkydiveSettings::GetSettings(Game::Mio);
		// if (SkydiveComp != nullptr && SkydiveComp.IsSkydiving())
		// 	SetActorLocation(ActorLocation + FVector(0, 0, SkydiveSettings.FallingVelocity * DeltaSeconds));
	}

	UFUNCTION()
	private void OnOverlapStartTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                   UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                   const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		if (bDisabled)
			return;

		auto SkydiveComp = UMeltdownSkydiveComponent::Get(Game::Mio);
		SkydiveComp.CurrentWorld = EMeltdownPhaseThreeFallingWorld(Math::WrapIndex(VideoIndex, 0, int(EMeltdownPhaseThreeFallingWorld::MAX)));
	}

	UFUNCTION()
	private void OnOverlapStopTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                  UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                  const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
	}
};

struct FMeltdownRequestedFallingVideo
{
	AMeltdownBossPhaseTheeFallingCylinder Cylinder;
	float PlayPriority = 0;

	int opCmp(const FMeltdownRequestedFallingVideo& Other) const
	{
		if (PlayPriority > Other.PlayPriority)
			return -1;
		else if (PlayPriority < Other.PlayPriority)
			return 1;
		else
			return 0;
	}
}

class UMeltdownBossPhaseFallingVideoManager : UActorComponent
{
	TArray<FMeltdownRequestedFallingVideo> RequestedVideos;
	TArray<AMeltdownBossPhaseTheeFallingCylinder> VideoSlots;
	UMaterialInstanceDynamic DynamicPostProcessMaterial;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		VideoSlots.SetNum(4);
	}

	void StartSkydive()
	{
		AMeltdownBossPhaseTheeFallingCylinder FirstCylinder = ActorList::GetSingle(AMeltdownBossPhaseTheeFallingCylinder);
		DynamicPostProcessMaterial = Material::CreateDynamicMaterialInstance(this, FirstCylinder.PostProcessMaterial);

		auto PostProcessComp = UPostProcessingComponent::Get(Game::Mio);
		PostProcessComp.PostProcessMaterial.Apply(DynamicPostProcessMaterial, this);

		for (AMeltdownBossPhaseTheeFallingCylinder Cylinder : TListedActors<AMeltdownBossPhaseTheeFallingCylinder>())
		{
			Cylinder.DynamicPostProcessMaterial = DynamicPostProcessMaterial;
			RequestPlaying(Cylinder);
		}
	}

	void RequestPlaying(AMeltdownBossPhaseTheeFallingCylinder Cylinder)
	{
		for (int i = 0, Count = RequestedVideos.Num(); i < Count; ++i)
		{
			if (RequestedVideos[i].Cylinder == Cylinder)
				return;
		}

		FMeltdownRequestedFallingVideo Request;
		Request.Cylinder = Cylinder;
		RequestedVideos.Add(Request);
	}

	void StopPlaying(AMeltdownBossPhaseTheeFallingCylinder Cylinder)
	{
		Cylinder.Stop();

		for (int i = 0, Count = RequestedVideos.Num(); i < Count; ++i)
		{
			if (RequestedVideos[i].Cylinder == Cylinder)
			{
				RequestedVideos.RemoveAt(i);
				break;
			}
		}

		int PlayingIndex = VideoSlots.FindIndex(Cylinder);
		if (PlayingIndex != -1)
			VideoSlots[PlayingIndex] = nullptr;
	}

	void MakeRelevant(AMeltdownBossPhaseTheeFallingCylinder Cylinder)
	{
		// Find an empty slot
		int Slot = VideoSlots.FindIndex(nullptr);
		VideoSlots[Slot] = Cylinder;

		Cylinder.StencilValue = Slot+1;
		Cylinder.Start();
	}

	void Prune(AMeltdownBossPhaseTheeFallingCylinder Cylinder)
	{
		int PlayingIndex = VideoSlots.FindIndex(Cylinder);
		if (PlayingIndex != -1)
			VideoSlots[PlayingIndex] = nullptr;
		Cylinder.Stop();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Update priority for requested videos
		float CameraHeight = Game::Mio.ViewLocation.Z;
		for (FMeltdownRequestedFallingVideo& RequestedVideo : RequestedVideos)
		{
			float Height = RequestedVideo.Cylinder.Cylinder.WorldLocation.Z;
			if (Height > CameraHeight)
			{
				RequestedVideo.PlayPriority = -1;
				continue;
			}

			float Distance = Math::Max(Math::Abs(CameraHeight - Height), 0.001);
			if (Distance > 80000)
			{
				RequestedVideo.PlayPriority = -1;
				continue;
			}

			RequestedVideo.PlayPriority = 1.0 / Distance;
		}

		// Sort videos by which ones we want the most
		RequestedVideos.Sort();

		// Stop videos we no longer want
		int CurrentVideoSlots = VideoSlots.Num();
		for (int i = 0; i < CurrentVideoSlots; ++i)
		{
			AMeltdownBossPhaseTheeFallingCylinder PlayingCylinder = VideoSlots[i];
			if (PlayingCylinder != nullptr)
			{
				bool bIsRelevant = false;

				for (int n = 0; n < CurrentVideoSlots; ++n)
				{
					if (RequestedVideos.Num() > n && RequestedVideos[n].Cylinder == PlayingCylinder && RequestedVideos[n].PlayPriority >= 0)
					{
						bIsRelevant = true;
						break;
					}
				}

				if (!bIsRelevant)
				{
					PlayingCylinder.Stop();
					VideoSlots[i] = nullptr;
				}
			}
		}

		// Start videos we want now
		for (int i = 0, Count = Math::Min(CurrentVideoSlots, RequestedVideos.Num()); i < Count; ++i)
		{
			if (RequestedVideos[i].PlayPriority < 0)
				continue;

			int PlayingSlot = VideoSlots.FindIndex(RequestedVideos[i].Cylinder);
			if (PlayingSlot == -1)
				MakeRelevant(RequestedVideos[i].Cylinder);
		}

		// Handle aspect ratio differences
		FVector2D ScreenResolution = SceneView::GetFullViewportResolution();
		if (ScreenResolution.X > 0 && ScreenResolution.Y > 0)
		{
			float VideoAspect = 16.0 / 9.0;
			float ScreenAspect = ScreenResolution.X / ScreenResolution.Y;

			FLinearColor ScreenUVBias;
			if (VideoAspect > ScreenAspect)
			{
				// Crop left and right
				float HorizScale = (ScreenAspect * 9.0) / 16.0;
				ScreenUVBias.R = -0.5 * (HorizScale - 1.0);
				ScreenUVBias.G = 0.0;
				ScreenUVBias.B = HorizScale;
				ScreenUVBias.A = 1.0;
			}
			else
			{
				// Crop top and bottom
				float VertScale = (16.0 / ScreenAspect) / 9.0;
				ScreenUVBias.R = 0.0;
				ScreenUVBias.G = -0.5 * (VertScale - 1.0);
				ScreenUVBias.B = 1.0;
				ScreenUVBias.A = VertScale;
			}

			if (DynamicPostProcessMaterial != nullptr)
				DynamicPostProcessMaterial.SetVectorParameterValue(n"ScreenUVBias", ScreenUVBias);

			for (auto Cylinder : VideoSlots)
			{
				if (Cylinder != nullptr && Cylinder.DynamicMaterial != nullptr)
					Cylinder.DynamicMaterial.SetVectorParameterValue(n"ScreenUVBias", ScreenUVBias);
			}
		}
	}
}