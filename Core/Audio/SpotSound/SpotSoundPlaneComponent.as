
class USpotSoundPlaneComponent : USpotSoundModeComponent
{
	default SpotMode = EHazeSpotSoundMode::Plane;

	UPROPERTY(VisibleInstanceOnly)
	UPrimitiveComponent LinkedMeshComponent = nullptr;

	private TArray<UHazeAudioListenerComponentBase> Listeners;
	private TArray<FAkSoundPosition> SoundPositions;

	const TArray<FAkSoundPosition>& GetPositions() property
	{
		return SoundPositions;
	}

#if EDITOR
	void OnModeAdded(USpotSoundComponent Spot) override
	{

	}
#endif

	void Start() override
	{
		if (LinkedMeshComponent == nullptr)
		{
			if(ParentSpot.LinkedMeshOwner.IsValid())
			{
				LinkedMeshComponent = UMeshComponent::Get(ParentSpot.LinkedMeshOwner.Get());
				if(LinkedMeshComponent == nullptr)
				{
					LinkedMeshComponent = UBrushComponent::Get(ParentSpot.LinkedMeshOwner.Get());
				}
			}
			else
				LinkedMeshComponent = UMeshComponent::Get(ParentSpot.GetOwner(), ParentSpot.LinkedMeshOwnerName);
		}

		if (LinkedMeshComponent == nullptr)
		{
		#if EDITOR
			Error(n"LogHazeAudio", f"{ParentSpot.GetOwner().GetActorLabel()} - {GetName()}, is missing it's LinkedMeshComponent!");
		#endif

			return;
		}

		if(SpotSoundDefData.SoundDef != nullptr)
		{
			FSpawnSoundDefSpotSoundParams SpotParams;
			SpotParams.SpotParent = Cast<AHazeActor>(GetOwner());
			SpotParams.SoundDefRef = SpotSoundDefData;

			if(ParentSpot.bLinkToZone)
			{
				SpotParams.LinkedOcclusionZone = ParentSpot.LinkedZone;
			}

			SpotParams.bLinkedZoneFollowRelevance = ParentSpot.bLinkToZone && ParentSpot.bLinkedZoneFollowRelevance;

			Audio::GetListeners(this, Listeners);
			SoundPositions.SetNum(Listeners.Num());
			UpdateComponentPositions();

			SoundDef::SpawnSoundDefSpot(SpotParams);
		}
		else
		{
			ParentSpot.GetAudioComponentAndEmitter(ParentSpot.Settings, false);
			ParentSpot.SetComponentTickEnabled(true);

			ParentSpot.SetupEmitter(ParentSpot.Settings, ParentSpot.Emitter, nullptr);
			ParentSpot.Emitter.GetListeners(Listeners);

			auto AudioComponent = ParentSpot.Emitter.GetAudioComponent();
			AudioComponent.SetAttenuationPadding(3000 + LinkedMeshComponent.BoundsRadius);

			SoundPositions.SetNum(Listeners.Num());
			UpdateComponentPositions();

			ParentSpot.Emitter.PostEvent(ParentSpot.Event, PostType = EHazeAudioEventPostType::Ambience);
			ParentSpot.Emitter.OnEventStarted.AddUFunction(this, n"OnEventStarted");
		}
	}

	void Stop() override
	{
		ParentSpot.SetComponentTickEnabled(false);
		// Will use a fade out for the stopping of the event.
		ParentSpot.InternalStop();
	}

	void UpdateComponentPositions()
	{
		if (LinkedMeshComponent == nullptr)
			return;

		for (int i = 0; i < Listeners.Num(); i++)
		{
			FVector PointOnBody;
			float Distance = LinkedMeshComponent.GetClosestPointOnCollision(Listeners[i].GetWorldLocation(), PointOnBody);
			if (Distance < 0)
				PointOnBody = LinkedMeshComponent.GetWorldLocation();

			SoundPositions[i].SetPosition(PointOnBody);
		}

		if (ParentSpot.Emitter != nullptr)
			ParentSpot.Emitter.AudioComponent.SetMultipleSoundPositions(SoundPositions);
	}

	// Restart tracking position updates.
	UFUNCTION()
	void OnEventStarted(const FHazeAudioPostEventInstance&in Instance)
	{
		if (!ParentSpot.IsComponentTickEnabled())
		{
			ParentSpot.SetComponentTickEnabled(true);
		}
	}

	void TickMode(float DeltaSeconds) override
	{
		if (!ParentSpot.Emitter.IsPlaying())
		{
			ParentSpot.SetComponentTickEnabled(false);
			return;
		}

		UpdateComponentPositions();
	}
}

#if EDITOR

#endif