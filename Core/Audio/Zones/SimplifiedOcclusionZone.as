

UCLASS(Meta = (NoSourceLink), HideCategories = "Rendering Cooking Debug")
class ASimplifiedOcclusionZone : AVolume
{
	default SetTickGroup(ETickingGroup::TG_PostUpdateWork);
	default BrushComponent.SetCollisionProfileName(n"AudioZone");

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
	default EditorIcon.SpriteName = "ZoneOcclusion";
	default EditorIcon.RelativeScale3D = FVector(2);
#endif

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComponent;
	default DisableComponent.AutoDisableRange = BrushComponent.BoundsRadius + Attenuation * 2; // * 2 == Some padding
	default DisableComponent.bAutoDisable = true;

	UPROPERTY(EditAnywhere)
	float Attenuation = 1000;

	// Only supports AudioComponents from SpotComponents or SoundDefs from the Actor.
	UPROPERTY(EditAnywhere)
	TArray<TSoftObjectPtr<AHazeActor>> LinkedActors;

	private FHazeAudioID Rtpc_Shared_Occlusion_Fade = FHazeAudioID("Rtpc_Shared_Occlusion_Fade");
	private TArray<UHazeAudioComponent> LinkedAudioComponents;

	private float ListenerRelevance = -1;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		DisableComponent.AutoDisableRange = BrushComponent.BoundsRadius + Attenuation * 2;
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DisableComponent.AutoDisableRange = BrushComponent.BoundsRadius + Attenuation * 2; // * 2 == Some padding
	}

	private bool bActorsLoaded = false;

	bool AwaitActors()
	{
		if (bActorsLoaded)
			return false;

		for (const auto& ActorRef : LinkedActors)
		{
			if(ActorRef.IsNull())
				continue;

			auto Actor = ActorRef.Get();
			if (Actor == nullptr || !Actor.HasActorBegunPlay())
				return true;
		}

		GatherAudioComponents(LinkedAudioComponents);
		bActorsLoaded = true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (AwaitActors())
			return;

		float NewRelevance = 1;

		for (auto Player: Game::Players)
		{
			FVector OutClosestPoint;
			auto Distance = BrushComponent.GetClosestPointOnCollision(Player.PlayerListener.WorldLocation, OutClosestPoint);
			float ListenerValue = Math::Clamp((Math::Max(Distance, 0) / Attenuation), 0 , 1);

			#if TEST
			if (AudioDebug::IsEnabled(EDebugAudioViewportVisualization::Zones))
			{
				PrintToScreenGraph(FName(f"[{GetActorNameOrLabel()}_{Player.Name}]"), 1 - ListenerValue, 
					FLinearColor::Purple, true, n"SimplifiedOcclusion"
					, Min = 0, Max = 1);
			}
			#endif

			NewRelevance = Math::Min(NewRelevance, ListenerValue);
		}

		if (Math::IsNearlyEqual(NewRelevance, ListenerRelevance))
			return;

		ListenerRelevance = NewRelevance;
		SetRtpc(LinkedAudioComponents, 1 - ListenerRelevance);
	}

	void SetRtpc(TArray<UHazeAudioComponent>& AudioComponents, float Value)
	{
		for (auto AudioComponent: LinkedAudioComponents)
		{
			if (AudioComponent == nullptr)
				continue;

			AudioComponent.SetRTPCOnEmitters(Rtpc_Shared_Occlusion_Fade, Value);
		}
	}

	void GatherAudioComponents(TArray<UHazeAudioComponent>& AudioComponents)
	{
		if (AudioComponents.Num() != 0)
			return;

		AudioComponents.Reset();

		TArray<USpotSoundComponent> SpotComps;

		for (const auto& ActorRef : LinkedActors)
		{
			auto Actor = ActorRef.Get();

			if(ActorRef.IsNull())
				continue;
			
			Actor.GetComponentsByClass(USpotSoundComponent, SpotComps);
			auto SoundDefContextComponent = Actor.GetComponentByClass(USoundDefContextComponent);
			if (SoundDefContextComponent != nullptr)
			{
				SoundDefContextComponent.GetAudioComponents(AudioComponents);
			}
		}

		if (SpotComps.Num() == 0)
			return;
		
		for (auto SpotComp: SpotComps)
		{
			if (SpotComp.Emitter != nullptr)
				AudioComponents.Add(SpotComp.Emitter.GetAudioComponent());
		}
	}
}