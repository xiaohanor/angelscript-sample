enum EVisibilityVolumeMode
{
	// Targeted actors are only visible when the player view is inside a volume making them visible
	OnlyVisibleWhenInside,
	// Targeted actors are hidden for player views that are inside the volume, cannot target actors inside this volume itself
	HideTargetsWhileInside,
	// Volume doesn't have any functionality by itself, but can be targeted by other volumes
	None,
}

enum EVisibilityResult
{
	// Targets should be made visible REGARDLESS of what any other volume says
	Visible,
	// Targets should be made invisible UNLESS other volumes say they should be visible
	Invisible,
	// Targets should be made visible ONLY if no other volumes say they should be invisible
	MaybeVisible,
	// Targets should be made invisible REGARDLESS of what any other volume says, even if it says Visible
	ForceInvisible,
}

enum EVisibilityVolumeApplyType
{
	PlayerCameraInside,
	PlayerActorInside,
}

class AVisibilityVolume : AHazeActor
{
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Behavior")
	EVisibilityVolumeMode Mode = EVisibilityVolumeMode::OnlyVisibleWhenInside;

	/** Any actors in these volumes will be affected. Can target volumes in different levels. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targets")
	TArray<TSoftObjectPtr<AVisibilityVolume>> TargetVolumes;

	/** Any actors in this list will be affected */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targets")
	TArray<TSoftObjectPtr<AActor>> TargetActors;

	/** All actors in the specified sublevels will be affected */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targets")
	TArray<TSoftObjectPtr<UWorld>> TargetLevels;

	/**
	 * Any actors placed in the level overlapping this volume will be targeted.
	 * NB: Only actors within the same sublevel are considered.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Contained Actors", Meta = (EditCondition = "Mode != EVisibilityVolumeMode::HideWhileInside", EditConditionHides))
	bool bTargetContainedActors = true;

	// Only apply visibility to contained actors with Static mobility
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Contained Actors", Meta = (EditCondition = "bTargetContainedActors && Mode != EVisibilityVolumeMode::HideWhileInside", EditConditionHides))
	bool bOnlyStaticContainedActors = false;

	// Only apply visibility to actors that are fully contained within the volume, instead of only overlapping it
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Contained Actors", Meta = (EditCondition = "bTargetContainedActors && Mode != EVisibilityVolumeMode::HideWhileInside", EditConditionHides))
	bool bOnlyFullyContainedActors = true;

	/** Actors contained within the volume to exclude from being targeted by it. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Contained Actors", Meta = (EditCondition = "bTargetContainedActors && Mode != EVisibilityVolumeMode::HideWhileInside", EditConditionHides))
	TArray<TSoftObjectPtr<AActor>> ExcludeContainedActors;

	/** Actors contained within the volume to exclude from being targeted by it. */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Contained Actors", Meta = (EditCondition = "bTargetContainedActors && Mode != EVisibilityVolumeMode::HideWhileInside", EditConditionHides))
	TArray<TSoftObjectPtr<AActor>> ContainedActors;

	/**
	 * Any actors placed in the level overlapping this volume will be targeted.
	 * NB: Only actors within the same sublevel are considered.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Activation")
	EVisibilityVolumeApplyType ApplyWhen;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent BoxComponent;
	default BoxComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default BoxComponent.BoxExtent = FVector(500, 500, 500);
	default BoxComponent.LineThickness = 50.0;
	default BoxComponent.ShapeColor = FColor::Emerald;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComponent;

	private TPerPlayer<bool> IsVolumeActive;
	private TSet<UPrimitiveComponent> ContainedSet;
	private TSet<UPrimitiveComponent> TargetSet;
	private TSet<TSoftObjectPtr<UWorld>> TargetLevelsSet;
	private bool bHasGatheredContainedActors = false;
	private bool bHasGatheredTargetedActors = false;
	private bool bIsInitialized = false;

	bool ShouldTargetActorsInSelf() const
	{
		return bTargetContainedActors && Mode != EVisibilityVolumeMode::HideTargetsWhileInside;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		UpdateContainedActors();
	}

	void UpdateContainedActors()
	{
		ContainedActors.Reset();

		ULevel CurrentLevel = GetLevel();
		if (CurrentLevel == nullptr)
			return;
		if (!ShouldTargetActorsInSelf())
			return;

		FTransform VolumeTransform = BoxComponent.GetWorldTransform();
		FBox VolumeBounds = BoxComponent.GetComponentLocalBoundingBox();

		for (AActor Actor : Editor::GetAllEditorWorldActorsOfClass(AActor))
		{
			if (Actor == nullptr)
				continue;
			if (Actor == this)
				continue;
			if (Actor.RootComponent == nullptr)
				continue;
			if (Actor.IsA(AGameSky))
				continue;

			if (bOnlyStaticContainedActors)
			{
				if (Actor.RootComponent.Mobility != EComponentMobility::Static)
					continue;
			}
			
			FVector BoundsOrigin;
			FVector BoundsExtent;
			Actor.GetActorBounds(true, BoundsOrigin, BoundsExtent);
			
			FBox ActorBox = FBox(BoundsOrigin - BoundsExtent, BoundsOrigin + BoundsExtent);
			ActorBox = ActorBox.InverseTransformBy(VolumeTransform);

			if (bOnlyFullyContainedActors)
			{
				if (!VolumeBounds.IsInside(ActorBox))
				{
					continue;
				}
			}
			else
			{
				if (!VolumeBounds.Intersect(ActorBox))
				{
					continue;
				}
			}

			if (ExcludeContainedActors.Contains(Actor))
				continue;

			ContainedActors.Add(Actor);
		}
	}
#endif

	void GatherContainedActors()
	{
		if (bHasGatheredContainedActors)
			return;

		TArray<USceneComponent> GatherList;
		TSet<USceneComponent> GatherSet;
		bHasGatheredContainedActors = true;

		for (auto Actor : TargetActors)
		{
			if (Actor.IsValid())
			{
				USceneComponent TargetRoot = Actor.Get().RootComponent;
				if (TargetRoot != nullptr)
					GatherList.Add(TargetRoot);
			}
		}

		if (ShouldTargetActorsInSelf())
		{
			for (auto Actor : ContainedActors)
			{
				if (Actor.IsValid())
				{
					USceneComponent TargetRoot = Actor.Get().RootComponent;
					if (TargetRoot != nullptr)
						GatherList.Add(TargetRoot);
				}
			}
		}

		for (int i = 0; i < GatherList.Num(); ++i)
		{
			USceneComponent Comp = GatherList[i];
			if (GatherSet.Contains(Comp))
				continue;

			UPrimitiveComponent PrimComp = Cast<UPrimitiveComponent>(Comp);
			if (PrimComp != nullptr)
				ContainedSet.Add(PrimComp);

			for (int ChildIndex = 0, ChildCount = Comp.GetNumChildrenComponents(); ChildIndex < ChildCount; ++ChildIndex)
			{
				USceneComponent Child = Comp.GetChildComponent(ChildIndex);
				if (!GatherSet.Contains(Child))
					GatherList.Add(Child);
			}
		}
	}

	void GatherTargetActors()
	{
		if (bHasGatheredTargetedActors)
			return;

		check(bHasGatheredContainedActors);
		TargetSet = ContainedSet;
		bHasGatheredTargetedActors = true;

		TargetLevelsSet.Empty();
		for (TSoftObjectPtr<UWorld> LevelRef : TargetLevels)
			TargetLevelsSet.Add(LevelRef);

		for (TSoftObjectPtr<AVisibilityVolume> VolumePtr : TargetVolumes)
		{
			AVisibilityVolume Volume = VolumePtr.Get();
			if (Volume != nullptr)
			{
				if (!Volume.bHasGatheredContainedActors)
					Volume.GatherContainedActors();
				TargetSet.Append(Volume.ContainedSet);
				for (TSoftObjectPtr<UWorld> LevelRef : Volume.TargetLevels)
					TargetLevelsSet.Add(LevelRef);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bHasGatheredContainedActors)
			GatherContainedActors();
		if (!bHasGatheredTargetedActors)
			GatherTargetActors();

		if (Mode != EVisibilityVolumeMode::None)
		{
			FTransform BoxTransform = BoxComponent.WorldTransform;
			FBox BoxBox = BoxComponent.GetComponentLocalBoundingBox();

			for (AHazePlayerCharacter Player : Game::Players)
			{
				FVector TestLocation;
				switch(ApplyWhen)
				{
					case EVisibilityVolumeApplyType::PlayerCameraInside:
						TestLocation = Player.ViewLocation;
					break;
					case EVisibilityVolumeApplyType::PlayerActorInside:
						TestLocation = Player.ActorCenterLocation;
					break;
				}

				bool bShouldBeActive = BoxBox.IsInsideOrOn(BoxTransform.InverseTransformPosition(TestLocation));
				if (bShouldBeActive)
				{
					if (!IsVolumeActive[Player] || !bIsInitialized)
					{
						IsVolumeActive[Player] = true;
						TEMPORAL_LOG(this).PersistentValue(f"{Player.Player :n} Active", true);
						UpdateVisibilityForTargetActors(Player);
					}
				}
				else
				{
					if (IsVolumeActive[Player] || !bIsInitialized)
					{
						IsVolumeActive[Player] = false;
						TEMPORAL_LOG(this).PersistentValue(f"{Player.Player :n} Active", false);
						UpdateVisibilityForTargetActors(Player);
					}
				}
			}
		}

		bIsInitialized = true;
	}

	EVisibilityResult GetVolumeVisibility(AHazePlayerCharacter Player) const
	{
		if (!bHasGatheredTargetedActors)
			return EVisibilityResult::Invisible;

		if (Mode == EVisibilityVolumeMode::OnlyVisibleWhenInside)
		{
			if (IsVolumeActive[Player])
			{
				return EVisibilityResult::Visible;
			}
			else
			{
				return EVisibilityResult::Invisible;
			}
		}
		else if (Mode == EVisibilityVolumeMode::HideTargetsWhileInside)
		{
			if (IsVolumeActive[Player])
			{
				return EVisibilityResult::ForceInvisible;
			}
			else
			{
				return EVisibilityResult::MaybeVisible;
			}
		}

		return EVisibilityResult::Invisible;
	}

	void UpdateVisibilityForTargetActors(AHazePlayerCharacter Player)
	{
		EHazeVisibilityBit Bit;
		if (Player.IsMio())
			Bit = EHazeVisibilityBit::HideFromMio;
		else
			Bit = EHazeVisibilityBit::HideFromZoe;

		EVisibilityResult SelfVisibility = GetVolumeVisibility(Player);
		if (SelfVisibility == EVisibilityResult::ForceInvisible)
		{
			// If we are forced invisible, that means all our targets must therefore also be invisible
			for (UPrimitiveComponent PrimComp : TargetSet)
			{
				if (PrimComp == nullptr)
					continue;
				PrimComp.SetComponentRenderVisibilityBit(Bit, true);
			}

			for (TSoftObjectPtr<UWorld> LevelRef : TargetLevelsSet)
			{
				// Ignore levels that aren't loaded in yet, or aren't loaded in anymore
				if (LevelRef.Get() == nullptr)
					continue;

				Player.SetLevelRenderedForPlayer(LevelRef, false);
			}
		}
		else if (SelfVisibility == EVisibilityResult::Visible)
		{
			TArray<AVisibilityVolume> ForceInvisibleVolumes;
			for (AVisibilityVolume ListedVolume : TListedActors<AVisibilityVolume>())
			{
				if (ListedVolume == nullptr)
					continue;
				if (ListedVolume == this)
					continue;
				if (ListedVolume.Mode == EVisibilityVolumeMode::None)
					continue;

				EVisibilityResult OtherResult = ListedVolume.GetVolumeVisibility(Player);
				if (OtherResult == EVisibilityResult::ForceInvisible)
					ForceInvisibleVolumes.Add(ListedVolume);
			}

			if (ForceInvisibleVolumes.Num() == 0)
			{
				// All our targets must be visible
				for (UPrimitiveComponent PrimComp : TargetSet)
				{
					if (PrimComp == nullptr)
						continue;
					PrimComp.SetComponentRenderVisibilityBit(Bit, false);
				}

				for (TSoftObjectPtr<UWorld> LevelRef : TargetLevelsSet)
				{
					// Ignore levels that aren't loaded in yet, or aren't loaded in anymore
					if (LevelRef.Get() == nullptr)
						continue;

					Player.SetLevelRenderedForPlayer(LevelRef, true);
				}
			}
			else if (ForceInvisibleVolumes.Num() == 1)
			{
				// Each target needs to check if it is being made force invisible by any other volumes
				AVisibilityVolume OtherForceInvisibleVolume = ForceInvisibleVolumes[0];
				for (UPrimitiveComponent PrimComp : TargetSet)
				{
					if (PrimComp == nullptr)
						continue;
					if (OtherForceInvisibleVolume.TargetSet.Contains(PrimComp))
						PrimComp.SetComponentRenderVisibilityBit(Bit, true);
					else
						PrimComp.SetComponentRenderVisibilityBit(Bit, false);
				}

				for (TSoftObjectPtr<UWorld> LevelRef : TargetLevelsSet)
				{
					// Ignore levels that aren't loaded in yet, or aren't loaded in anymore
					if (LevelRef.Get() == nullptr)
						continue;

					if (OtherForceInvisibleVolume.TargetLevelsSet.Contains(LevelRef))
						Player.SetLevelRenderedForPlayer(LevelRef, false);
					else
						Player.SetLevelRenderedForPlayer(LevelRef, true);
				}
			}
			else
			{
				// Each target needs to check if it is being made force invisible by any other volumes
				for (UPrimitiveComponent PrimComp : TargetSet)
				{
					if (PrimComp == nullptr)
						continue;

					bool bTargetedByForceInvisibleVolume = false;
					for (AVisibilityVolume OtherVolume : ForceInvisibleVolumes)
					{
						if (OtherVolume.TargetSet.Contains(PrimComp))
							bTargetedByForceInvisibleVolume = true;
					}

					if (bTargetedByForceInvisibleVolume)
						PrimComp.SetComponentRenderVisibilityBit(Bit, true);
					else
						PrimComp.SetComponentRenderVisibilityBit(Bit, false);
				}

				for (TSoftObjectPtr<UWorld> LevelRef : TargetLevelsSet)
				{
					// Ignore levels that aren't loaded in yet, or aren't loaded in anymore
					if (LevelRef.Get() == nullptr)
						continue;

					bool bTargetedByForceInvisibleVolume = false;
					for (AVisibilityVolume OtherVolume : ForceInvisibleVolumes)
					{
						if (OtherVolume.TargetLevelsSet.Contains(LevelRef))
							bTargetedByForceInvisibleVolume = true;
					}

					if (bTargetedByForceInvisibleVolume)
						Player.SetLevelRenderedForPlayer(LevelRef, false);
					else
						Player.SetLevelRenderedForPlayer(LevelRef, true);
				}
			}
		}
		else if (SelfVisibility == EVisibilityResult::Invisible)
		{
			// Are any other volumes currently visible?
			TArray<AVisibilityVolume> OtherVisibleVolumes;
			TArray<AVisibilityVolume> ForceInvisibleVolumes;

			for (AVisibilityVolume ListedVolume : TListedActors<AVisibilityVolume>())
			{
				if (ListedVolume == nullptr)
					continue;
				if (ListedVolume == this)
					continue;
				if (ListedVolume.Mode == EVisibilityVolumeMode::None)
					continue;

				EVisibilityResult OtherResult = ListedVolume.GetVolumeVisibility(Player);
				if (OtherResult == EVisibilityResult::Visible)
					OtherVisibleVolumes.Add(ListedVolume);
				else if (OtherResult == EVisibilityResult::ForceInvisible)
					ForceInvisibleVolumes.Add(ListedVolume);
			}

			if (OtherVisibleVolumes.Num() == 0)
			{
				// No other volumes are visible, we can set all the targets to be hidden
				for (UPrimitiveComponent PrimComp : TargetSet)
				{
					if (PrimComp == nullptr)
						continue;
					PrimComp.SetComponentRenderVisibilityBit(Bit, true);
				}

				for (TSoftObjectPtr<UWorld> LevelRef : TargetLevelsSet)
				{
					// Ignore levels that aren't loaded in yet, or aren't loaded in anymore
					if (LevelRef.Get() == nullptr)
						continue;

					Player.SetLevelRenderedForPlayer(LevelRef, false);
				}
			}
			else if (OtherVisibleVolumes.Num() == 1 && ForceInvisibleVolumes.Num() == 0)
			{
				// Each target needs to check if it is being made visible by any other volumes
				AVisibilityVolume OtherVolume = OtherVisibleVolumes[0];
				for (UPrimitiveComponent PrimComp : TargetSet)
				{
					if (PrimComp == nullptr)
						continue;
					if (OtherVolume.TargetSet.Contains(PrimComp))
						PrimComp.SetComponentRenderVisibilityBit(Bit, false);
					else
						PrimComp.SetComponentRenderVisibilityBit(Bit, true);
				}

				for (TSoftObjectPtr<UWorld> LevelRef : TargetLevelsSet)
				{
					// Ignore levels that aren't loaded in yet, or aren't loaded in anymore
					if (LevelRef.Get() == nullptr)
						continue;

					if (OtherVolume.TargetLevelsSet.Contains(LevelRef))
						Player.SetLevelRenderedForPlayer(LevelRef, true);
					else
						Player.SetLevelRenderedForPlayer(LevelRef, false);
				}
			}
			else if (ForceInvisibleVolumes.Num() == 0)
			{
				// Each target needs to check if it is being made visible by any other volumes
				for (UPrimitiveComponent PrimComp : TargetSet)
				{
					if (PrimComp == nullptr)
						continue;

					bool bTargetedByOtherVisibleVolume = false;
					for (AVisibilityVolume OtherVolume : OtherVisibleVolumes)
					{
						if (OtherVolume.TargetSet.Contains(PrimComp))
							bTargetedByOtherVisibleVolume = true;
					}

					if (bTargetedByOtherVisibleVolume)
						PrimComp.SetComponentRenderVisibilityBit(Bit, false);
					else
						PrimComp.SetComponentRenderVisibilityBit(Bit, true);
				}

				for (TSoftObjectPtr<UWorld> LevelRef : TargetLevelsSet)
				{
					// Ignore levels that aren't loaded in yet, or aren't loaded in anymore
					if (LevelRef.Get() == nullptr)
						continue;

					bool bTargetedByOtherVisibleVolume = false;
					for (AVisibilityVolume OtherVolume : OtherVisibleVolumes)
					{
						if (OtherVolume.TargetLevelsSet.Contains(LevelRef))
							bTargetedByOtherVisibleVolume = true;
					}

					if (bTargetedByOtherVisibleVolume)
						Player.SetLevelRenderedForPlayer(LevelRef, true);
					else
						Player.SetLevelRenderedForPlayer(LevelRef, false);
				}
			}
			else
			{
				// Each target needs to check if it is being made visible or force invisible by any other volumes
				for (UPrimitiveComponent PrimComp : TargetSet)
				{
					if (PrimComp == nullptr)
						continue;

					bool bTargetedByOtherVisibleVolume = false;
					for (AVisibilityVolume OtherVolume : OtherVisibleVolumes)
					{
						if (OtherVolume.TargetSet.Contains(PrimComp))
							bTargetedByOtherVisibleVolume = true;
					}

					bool bTargetedByForceInvisibleVolume = false;
					for (AVisibilityVolume OtherVolume : ForceInvisibleVolumes)
					{
						if (OtherVolume.TargetSet.Contains(PrimComp))
							bTargetedByForceInvisibleVolume = true;
					}

					if (bTargetedByOtherVisibleVolume && !bTargetedByForceInvisibleVolume)
						PrimComp.SetComponentRenderVisibilityBit(Bit, false);
					else
						PrimComp.SetComponentRenderVisibilityBit(Bit, true);
				}

				for (TSoftObjectPtr<UWorld> LevelRef : TargetLevelsSet)
				{
					// Ignore levels that aren't loaded in yet, or aren't loaded in anymore
					if (LevelRef.Get() == nullptr)
						continue;

					bool bTargetedByOtherVisibleVolume = false;
					for (AVisibilityVolume OtherVolume : OtherVisibleVolumes)
					{
						if (OtherVolume.TargetLevelsSet.Contains(LevelRef))
							bTargetedByOtherVisibleVolume = true;
					}

					bool bTargetedByForceInvisibleVolume = false;
					for (AVisibilityVolume OtherVolume : ForceInvisibleVolumes)
					{
						if (OtherVolume.TargetLevelsSet.Contains(LevelRef))
							bTargetedByForceInvisibleVolume = true;
					}

					if (bTargetedByOtherVisibleVolume && !bTargetedByForceInvisibleVolume)
						Player.SetLevelRenderedForPlayer(LevelRef, true);
					else
						Player.SetLevelRenderedForPlayer(LevelRef, false);
				}
			}
		}
		else if (SelfVisibility == EVisibilityResult::MaybeVisible)
		{
			// Are any other volumes currently invisible?
			TArray<AVisibilityVolume> AnyInvisibleVolumes;
			TArray<AVisibilityVolume> ForceInvisibleVolumes;
			TArray<AVisibilityVolume> VisibleVolumes;
			for (AVisibilityVolume ListedVolume : TListedActors<AVisibilityVolume>())
			{
				if (ListedVolume == nullptr)
					continue;
				if (ListedVolume == this)
					continue;
				if (ListedVolume.Mode == EVisibilityVolumeMode::None)
					continue;

				EVisibilityResult OtherResult = ListedVolume.GetVolumeVisibility(Player);
				if (OtherResult == EVisibilityResult::Invisible)
				{
					AnyInvisibleVolumes.Add(ListedVolume);
				}
				else if (OtherResult == EVisibilityResult::ForceInvisible)
				{
					AnyInvisibleVolumes.Add(ListedVolume);
					ForceInvisibleVolumes.Add(ListedVolume);
				}
				else if (OtherResult == EVisibilityResult::Visible)
				{
					VisibleVolumes.Add(ListedVolume);
				}
			}

			if (AnyInvisibleVolumes.Num() == 0)
			{
				// No volumes are making anything invisible, so our contained actors should definitely be visible
				for (UPrimitiveComponent PrimComp : TargetSet)
				{
					if (PrimComp == nullptr)
						continue;
					PrimComp.SetComponentRenderVisibilityBit(Bit, false);
				}

				for (TSoftObjectPtr<UWorld> LevelRef : TargetLevelsSet)
				{
					// Ignore levels that aren't loaded in yet, or aren't loaded in anymore
					if (LevelRef.Get() == nullptr)
						continue;

					Player.SetLevelRenderedForPlayer(LevelRef, true);
				}
			}
			else if (AnyInvisibleVolumes.Num() == 1 && VisibleVolumes.Num() == 0)
			{
				// Each target needs to check if it is being made invisible by any other volumes
				AVisibilityVolume InvisibleVolume = AnyInvisibleVolumes[0];
				for (UPrimitiveComponent PrimComp : TargetSet)
				{
					if (PrimComp == nullptr)
						continue;
					if (InvisibleVolume.TargetSet.Contains(PrimComp))
						PrimComp.SetComponentRenderVisibilityBit(Bit, true);
					else
						PrimComp.SetComponentRenderVisibilityBit(Bit, false);
				}

				for (TSoftObjectPtr<UWorld> LevelRef : TargetLevelsSet)
				{
					// Ignore levels that aren't loaded in yet, or aren't loaded in anymore
					if (LevelRef.Get() == nullptr)
						continue;

					if (InvisibleVolume.TargetLevelsSet.Contains(LevelRef))
						Player.SetLevelRenderedForPlayer(LevelRef, false);
					else
						Player.SetLevelRenderedForPlayer(LevelRef, true);
				}
			}
			else if (VisibleVolumes.Num() == 0)
			{
				// Each target needs to check if it is being made invisible by any other volumes
				for (UPrimitiveComponent PrimComp : TargetSet)
				{
					if (PrimComp == nullptr)
						continue;

					bool bTargetedByInvisibleVolume = false;
					for (AVisibilityVolume OtherVolume : AnyInvisibleVolumes)
					{
						if (OtherVolume.TargetSet.Contains(PrimComp))
						{
							bTargetedByInvisibleVolume = true;
							break;
						}
					}

					if (bTargetedByInvisibleVolume)
						PrimComp.SetComponentRenderVisibilityBit(Bit, true);
					else
						PrimComp.SetComponentRenderVisibilityBit(Bit, false);
				}

				for (TSoftObjectPtr<UWorld> LevelRef : TargetLevelsSet)
				{
					// Ignore levels that aren't loaded in yet, or aren't loaded in anymore
					if (LevelRef.Get() == nullptr)
						continue;

					bool bTargetedByInvisibleVolume = false;
					for (AVisibilityVolume OtherVolume : AnyInvisibleVolumes)
					{
						if (OtherVolume.TargetLevelsSet.Contains(LevelRef))
						{
							bTargetedByInvisibleVolume = true;
							break;
						}
					}

					if (bTargetedByInvisibleVolume)
						Player.SetLevelRenderedForPlayer(LevelRef, false);
					else
						Player.SetLevelRenderedForPlayer(LevelRef, true);
				}
			}
			else
			{
				// Each target needs to check if it is being made invisible by any other volumes
				for (UPrimitiveComponent PrimComp : TargetSet)
				{
					if (PrimComp == nullptr)
						continue;

					bool bTargetedByInvisibleVolume = false;
					for (AVisibilityVolume OtherVolume : AnyInvisibleVolumes)
					{
						if (OtherVolume.TargetSet.Contains(PrimComp))
						{
							bTargetedByInvisibleVolume = true;
							break;
						}
					}

					if (bTargetedByInvisibleVolume)
					{
						// If it's not targeted by ForceInvisible but it _is_ targeted by Visible, then it should still be visible
						bool bTargetedByForceInvisibleVolume = false;
						for (AVisibilityVolume OtherVolume : ForceInvisibleVolumes)
						{
							if (OtherVolume.TargetSet.Contains(PrimComp))
							{
								bTargetedByForceInvisibleVolume = true;
								break;
							}
						}

						if (!bTargetedByForceInvisibleVolume)
						{
							for (AVisibilityVolume OtherVolume : VisibleVolumes)
							{
								if (OtherVolume.TargetSet.Contains(PrimComp))
								{
									bTargetedByInvisibleVolume = false;
									break;
								}
							}
						}
					}

					if (bTargetedByInvisibleVolume)
						PrimComp.SetComponentRenderVisibilityBit(Bit, true);
					else
						PrimComp.SetComponentRenderVisibilityBit(Bit, false);
				}

				for (TSoftObjectPtr<UWorld> LevelRef : TargetLevelsSet)
				{
					// Ignore levels that aren't loaded in yet, or aren't loaded in anymore
					if (LevelRef.Get() == nullptr)
						continue;

					bool bTargetedByInvisibleVolume = false;
					for (AVisibilityVolume OtherVolume : AnyInvisibleVolumes)
					{
						if (OtherVolume.TargetLevelsSet.Contains(LevelRef))
						{
							bTargetedByInvisibleVolume = true;
							break;
						}
					}

					if (bTargetedByInvisibleVolume)
					{
						// If it's not targeted by ForceInvisible but it _is_ targeted by Visible, then it should still be visible
						bool bTargetedByForceInvisibleVolume = false;
						for (AVisibilityVolume OtherVolume : ForceInvisibleVolumes)
						{
							if (OtherVolume.TargetLevelsSet.Contains(LevelRef))
							{
								bTargetedByForceInvisibleVolume = true;
								break;
							}
						}

						if (!bTargetedByForceInvisibleVolume)
						{
							for (AVisibilityVolume OtherVolume : VisibleVolumes)
							{
								if (OtherVolume.TargetLevelsSet.Contains(LevelRef))
								{
									bTargetedByInvisibleVolume = false;
									break;
								}
							}
						}
					}

					if (bTargetedByInvisibleVolume)
						Player.SetLevelRenderedForPlayer(LevelRef, false);
					else
						Player.SetLevelRenderedForPlayer(LevelRef, true);
				}
			}
		}
		else
		{
			check(false);
		}
	}
}

#if EDITOR
class UVisibilityVolumeEditorSubsystem : UHazeEditorSubsystem
{
	UFUNCTION(BlueprintOverride)
	void OnEditorLevelsRebuilt()
	{
		for (AVisibilityVolume ListedVolume : TListedActors<AVisibilityVolume>())
			ListedVolume.UpdateContainedActors();
	}
}
#endif