struct FBackdropLaserGroup
{
	FVector Origin;
	FVector Direction;

	#if EDITOR
	FLinearColor Color = FLinearColor::MakeRandomColor();
	#endif

	UPROPERTY()
	UHazeAudioEmitter Emitter;

	UPROPERTY()
	TArray<AMaxSecurityBackdropLaser> Lasers;

	UPROPERTY(Transient)
	TArray<FAkSoundPosition> SoundPositions;

	bool bHasStartedLasers = false;
	float LastPitch = 0;
	bool bMovingUpwards = false;
};

UCLASS(Abstract)
class UWorld_Prison_MaxSecurity_BackdropLasers_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	// This SD assumes it will be linked to a parent with attached actors of class AMaxSecurityBackdropLaser
	// Tracks all lasers within this group.

	// Positioning;
	// One position for each listener and laser pair.
	// Pair, or group (more then two);
	// A pair is based on distance/dot from their origin.

	UPROPERTY()
	float GroupingRadius = 1000;

	UPROPERTY()
	float GroupingDot = 0.9;

	UPROPERTY()
	float MaxAttenuationPaddingInLevel = 250 * 100;

	private TArray<FBackdropLaserGroup> LaserGroups;
	private TArray<UHazeAudioEmitter> ActiveLaserGroupEmitters;

	// private TArray<FAkSoundPosition> SoundPositions;
	private TArray<float> ListenerDistance;
	private bool bAnyLasersStarted = false;
	private USpotSoundComponent SpotComponent;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		AActor TargetActor = HazeOwner;

		SpotComponent = USpotSoundComponent::Get(HazeOwner);
		if (SpotComponent != nullptr && !SpotComponent.LinkedMeshOwner.IsNull())
		{
			TargetActor = SpotComponent.LinkedMeshOwner.Get();
		}

		TArray<AActor> LasersFound;
		TargetActor.GetAttachedActors(LasersFound);

		for (auto LaserActor: LasersFound)
		{
			auto Laser = Cast<AMaxSecurityBackdropLaser>(LaserActor);
			if (Laser == nullptr)
				continue;

			bool bFoundGroup = false;

			for (auto& LaserGroup: LaserGroups)
			{
				if (LaserGroup.Origin.DistSquared(Laser.LaserRoot.WorldLocation) > GroupingRadius * GroupingRadius)
					continue;

				if (LaserGroup.Direction.DotProduct(Laser.LaserRoot.ForwardVector) < GroupingDot)
					continue;

				bFoundGroup = true;
				LaserGroup.Lasers.Add(Laser);
			}

			if (!bFoundGroup)
			{
				auto NewGroup = FBackdropLaserGroup();
				NewGroup.Origin = Laser.LaserRoot.WorldLocation;
				NewGroup.Direction = Laser.LaserRoot.ForwardVector;
				NewGroup.Lasers.Add(Laser);
				NewGroup.LastPitch = Laser.LaserRoot.RelativeRotation.Pitch;

				LaserGroups.Add(NewGroup);
			}
		}

		FSoundDefAudioComponentData InitialAttachment;
		InitialAttachment.bUseWorldTransform = false;
		InitialAttachment.AudioCompName = n"BackdropLasers";

		for (int i=0; i < LaserGroups.Num(); ++i)
		{
			SetupGroup(i, InitialAttachment);
		}
	}

	void SetupGroup(int index, FSoundDefAudioComponentData& AttachmentData)
	{
		auto& LaserGroup = LaserGroups[index];
		AttachmentData.AttachComp = LaserGroup.Lasers[0].LaserRoot;
		LaserGroup.Emitter = AddEmitterByAttachment(AttachmentData);

		// Dos listeners
		SetSoundPositionNum(LaserGroup.SoundPositions, 2);
		LaserGroup.Emitter.GetAudioComponent().SetAttenuationPadding(MaxAttenuationPaddingInLevel);
	}

	void SetSoundPositionNum(TArray<FAkSoundPosition>& SoundPositions, int Num)
	{
		if (SoundPositions.Num() == Num)
			return;

		SoundPositions.SetNum(Num);
		for (int i=0; i < SoundPositions.Num(); ++i)
		{
			SoundPositions[i] = FAkSoundPosition();
		}
	}

	UFUNCTION(BlueprintEvent,Meta = (AutoCreateBPNode))
	void OnLaserActivated(UHazeAudioEmitter Emitter) {}

	UFUNCTION(BlueprintEvent,Meta = (AutoCreateBPNode))
	void OnLaserDeactivated(UHazeAudioEmitter Emitter) {}

	UFUNCTION(BlueprintEvent,Meta = (AutoCreateBPNode))
	void OnLasersActivated(UHazeAudioEmitter FirstActivatedEmitter) {}

	UFUNCTION(BlueprintEvent,Meta = (AutoCreateBPNode))
	void OnLasersRevealed(UHazeAudioEmitter FirstActivatedEmitter) {}

	UFUNCTION(BlueprintEvent,Meta = (AutoCreateBPNode))
	void OnLaserMovingUpwards(UHazeAudioEmitter Emitter) {}

	UFUNCTION(BlueprintEvent,Meta = (AutoCreateBPNode))
	void OnLaserMovingDownwards(UHazeAudioEmitter Emitter) {}

	UFUNCTION(BlueprintPure)
	void GetAllLaserEmitters(TArray<UHazeAudioEmitter>&out LaserEmitters)
	{
		LaserEmitters = ActiveLaserGroupEmitters;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		TArray<UHazeAudioListenerComponentBase> Listeners;
		Audio::GetListeners(this, Listeners);
		if (Listeners.Num() != ListenerDistance.Num())
		{
			ListenerDistance.SetNum(Listeners.Num());
		}

		for (int i=0; i < LaserGroups.Num(); ++i)
		{
			auto& LaserGroup = LaserGroups[i];

			// Reset
			for (int j = ListenerDistance.Num() -1; j >= 0; --j)
				ListenerDistance[j] = MAX_flt;

			auto FirstLaser = LaserGroup.Lasers[0];
			bool bLaserActive = Math::IsNearlyZero(FirstLaser.LaserLength) == false;
			if (bLaserActive != LaserGroup.bHasStartedLasers)
			{
				LaserGroup.bHasStartedLasers = bLaserActive;

				if (bAnyLasersStarted == false)
				{
					bAnyLasersStarted = true;
					// Was is snapped or is it extending
					if (Math::IsNearlyEqual(FirstLaser.LaserLength, FirstLaser.MaxLength))
					{
						OnLasersActivated(LaserGroup.Emitter);
					}
					else
					{
						OnLasersRevealed(LaserGroup.Emitter);		
					}
				}

				if (bLaserActive)
				{
					OnLaserActivated(LaserGroup.Emitter);
					ActiveLaserGroupEmitters.Add(LaserGroup.Emitter);
				}
				else
				{
					OnLaserDeactivated(LaserGroup.Emitter);
					ActiveLaserGroupEmitters.Remove(LaserGroup.Emitter);
				}
			}

			auto CurrentPitch = FirstLaser.LaserRoot.RelativeRotation.Pitch;
			if (LaserGroup.LastPitch != CurrentPitch)
			{
				// Is it moving upwards or downwards?
				bool bMovingUpwards = CurrentPitch > LaserGroup.LastPitch;
				if (bMovingUpwards != LaserGroup.bMovingUpwards)
				{
					LaserGroup.bMovingUpwards = bMovingUpwards;

					if (bMovingUpwards)
						OnLaserMovingUpwards(LaserGroup.Emitter);
					else
						OnLaserMovingDownwards(LaserGroup.Emitter);
				}

				LaserGroup.LastPitch = CurrentPitch;
			}

			// Get the closest position for each laser group, for each listener
			for (auto Laser: LaserGroup.Lasers)
			{
				#if EDITOR
				if (IsDebugging())
					Debug::DrawDebugDirectionArrow(Laser.LaserRoot.WorldLocation, Laser.LaserRoot.ForwardVector, GroupingRadius, 100, LaserGroup.Color, 50);
				#endif

				for (int index = ListenerDistance.Num() -1; index >= 0; --index)
				{
					auto ClosestPositionOnLine = Laser.GetClosestPointOnLine(Listeners[index].WorldLocation);
					auto DistSquared = Listeners[index].WorldLocation.DistSquared(ClosestPositionOnLine);

					if (DistSquared < ListenerDistance[index])
					{
						ListenerDistance[index] = DistSquared;
						LaserGroup.SoundPositions[index].SetPosition(ClosestPositionOnLine);
					}
				}
			}

			LaserGroup.Emitter.GetAudioComponent().SetMultipleSoundPositions(LaserGroup.SoundPositions);
		}

	}
}