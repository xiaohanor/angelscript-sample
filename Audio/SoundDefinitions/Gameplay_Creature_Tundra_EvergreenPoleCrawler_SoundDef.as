
UCLASS(Abstract)
class UGameplay_Creature_Tundra_EvergreenPoleCrawler_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	const FHazeAudioID FootstepRateRTPCID = FHazeAudioID("Rtpc_Creature_EvergreenPoleCrawler_Footstep_TriggerRate");
	const FHazeAudioID VocalizationRateRTPCID = FHazeAudioID("Rtpc_Creature_EvergreenPoleCrawler_Vocalizations_TriggerRate");

	TArray<FAkSoundPosition> GroupPositions;

	AEvergreenPoleCrawlerGroup Group;
	const float DEFAULT_FOOTSTEP_TRIGGER_RATE = 0.4;

	UPROPERTY(EditAnywhere)
	float VocalizationsTriggerRateMin = 0.5;

	UPROPERTY(EditAnywhere)
	float VocalizationsTriggerRateMax = 25.0;

	UPROPERTY(EditAnywhere, Meta = (ClampMin = 0, ClampMax=3, UIMin=0, UIMax=3))
	int MovementLoopIndex = 0;

	UPROPERTY(BlueprintReadOnly)
	float IsInViewValue = 0.0;

	UFUNCTION(BlueprintEvent)
	void StartMoving() {};

	UFUNCTION(BlueprintEvent)
	void StopMoving() {};

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{		
		Group = Cast<AEvergreenPoleCrawlerGroup>(HazeOwner);
		AEvergreenPoleCrawler Crawler = Cast<AEvergreenPoleCrawler>(HazeOwner);

		if(IsGroup())
		{
			if(!devEnsure(Group.GroupedCrawlers.Num() > 0, f"No grouped crawlers set for SoundDef used for {HazeOwner}"))
				return;

			GroupPositions.SetNum(Group.GroupedCrawlers.Num());
			Crawler = Group.GroupedCrawlers[0];
		}	

		const float AnimationFootstepRate = Math::GetMappedRangeValueUnclamped(FVector2D(0.25, 1.0), FVector2D(DEFAULT_FOOTSTEP_TRIGGER_RATE, 0.1), Crawler.SkelMesh.AnimationData.SavedPlayRate);
		DefaultEmitter.SetRTPC(FootstepRateRTPCID, AnimationFootstepRate, 0.0);	

		const float RandomVocalizationsTriggerRateValue = Math::RandRange(VocalizationsTriggerRateMin, VocalizationsTriggerRateMax);
		const float VocalizationsTriggerRateMapped = Math::GetMappedRangeValueClamped(FVector2D(VocalizationsTriggerRateMin, VocalizationsTriggerRateMax), FVector2D(3.0, 10.0), RandomVocalizationsTriggerRateValue);

		DefaultEmitter.SetRTPC(VocalizationRateRTPCID, VocalizationsTriggerRateMapped, 0.0);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Group != nullptr && GroupPositions.Num() == 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Group != nullptr && GroupPositions.Num() == 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		//if(IsGroup())
			StartMoving();

		DefaultEmitter.AudioComponent.GetZoneOcclusion(true, nullptr, true);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is Group"))
	bool IsGroup() const
	{
		return Group != nullptr;
	}

	UFUNCTION(BlueprintPure)
	protected bool ShouldTrackEmitterPos() const
	{
		return SceneView::IsFullScreen() || Game::GetMio().GetCurrentGameplayPerspectiveMode() == EPlayerMovementPerspectiveMode::SideScroller;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(IsGroup())
		{
			SetGroupPositioning();
		}

		if(ShouldTrackEmitterPos())
		{
			FVector EmitterPos = DefaultEmitter.AudioComponent.GetWorldLocation();
			if(IsGroup())
			{
				float ClosestEmitterDistanceSqrd = MAX_flt;
				for(auto Pos : GroupPositions)
				{
					auto ClosestPlayer = DefaultEmitter.AudioComponent.GetClosestPlayer();
					if (ClosestPlayer == nullptr)
 						continue;

					const float PosDstSqrd = Pos.Position.DistSquared(ClosestPlayer.ActorLocation);
					if(ClosestEmitterDistanceSqrd > PosDstSqrd)
					{
						ClosestEmitterDistanceSqrd = PosDstSqrd;
						EmitterPos = Pos.Position;
					}
				}
			}

			if(Game::GetMio().GetCurrentGameplayPerspectiveMode() == EPlayerMovementPerspectiveMode::SideScroller)
			{
				FVector2D _;	
				float _Y = 0.0;
				if(SceneView::IsInView(Game::GetMio(), EmitterPos))
					IsInViewValue = 1.0;
				else
					IsInViewValue = 0.0;

			}

			if(SceneView::IsFullScreen())
			{
				FVector2D _;	
				float X = 0.0;
				float _Y = 0.0;
				Audio::GetScreenPositionRelativePanningValue(EmitterPos, _, X, _Y);
				DefaultEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, X, 0.0);
			}
		}
	}

	private void SetGroupPositioning()
	{
		int GroupCount = 0;
		for(int i = 0; i < Group.GroupedCrawlers.Num(); ++i)
		{
			if (Group.GroupedCrawlers[i] != nullptr && Group.GroupedCrawlers[i].bHasBeenCaught == false)
			{
				GroupPositions[GroupCount].SetPosition(Group.GroupedCrawlers[i].SkelMesh.GetWorldLocation());
				++GroupCount;
			}
		}

		// Will only lower the total count
		if (GroupCount != GroupPositions.Num())
			GroupPositions.SetNum(GroupCount);

		DefaultEmitter.AudioComponent.SetMultipleSoundPositions(GroupPositions);
	}
}