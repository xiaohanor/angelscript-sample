class AWorldLinkDoubleActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent ScifiRoot;
	UPROPERTY(DefaultComponent)
	USceneComponent FantasyRoot;

	UPROPERTY(EditAnywhere, BlueprintHidden)
	bool bScifiEnabled = true;
	UPROPERTY(EditAnywhere, BlueprintHidden)
	bool bFantasyEnabled = true;

	private AHazeWorldLinkAnchor BaseAnchor;
	private AHazeWorldLinkAnchor OppositeAnchor;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		BaseAnchor = WorldLink::GetClosestAnchor(ActorLocation);
		OppositeAnchor = WorldLink::GetOppositeAnchor(BaseAnchor);
		RepositionRoots();
	}
#endif

	EHazeWorldLinkLevel GetBaseSoftSplit() const
	{
		return BaseAnchor.AnchorLevel;
	}

	FVector GetLocationBasedOnActorLocation(EHazeWorldLinkLevel Split, FVector Location) const
	{
		if (Split == BaseAnchor.AnchorLevel)
			return Location;
		else
			return Location - BaseAnchor.ActorLocation + OppositeAnchor.ActorLocation;
	}

	UFUNCTION()
	void SetSplitEnabled(EHazeWorldLinkLevel Split, bool bValue)
	{
		if (Split == EHazeWorldLinkLevel::Fantasy)
			SetFantasyEnabled(bValue);
		else
			SetScifiEnabled(bValue);
	}

	UFUNCTION()
	void SetFantasyEnabled(bool bValue)
	{
		bFantasyEnabled = bValue;

		TArray<USceneComponent> Components;
		FantasyRoot.GetChildrenComponents(true, Components);

		for (USceneComponent Comp : Components)
		{
			auto PrimComp = Cast<UPrimitiveComponent>(Comp);
			if (PrimComp != nullptr)
			{
				if (bValue)
				{
					PrimComp.RemoveComponentVisualsBlocker(this);
					PrimComp.RemoveComponentCollisionBlocker(this);
				}
				else
				{
					PrimComp.AddComponentVisualsBlocker(this);
					PrimComp.AddComponentCollisionBlocker(this);
				}
			}
		}
	}

	UFUNCTION()
	void SetScifiEnabled(bool bValue)
	{
		bFantasyEnabled = bValue;

		TArray<USceneComponent> Components;
		ScifiRoot.GetChildrenComponents(true, Components);

		for (USceneComponent Comp : Components)
		{
			auto PrimComp = Cast<UPrimitiveComponent>(Comp);
			if (PrimComp != nullptr)
			{
				if (bValue)
				{
					PrimComp.RemoveComponentVisualsBlocker(this);
					PrimComp.RemoveComponentCollisionBlocker(this);
				}
				else
				{
					PrimComp.AddComponentVisualsBlocker(this);
					PrimComp.AddComponentCollisionBlocker(this);
				}
			}
		}
	}

	void SetActorRootInsideSplit(EHazeWorldLinkLevel Split)
	{
		if (Split == BaseAnchor.AnchorLevel)
			return;

		auto OtherAnchor = OppositeAnchor;
		OppositeAnchor = BaseAnchor;
		BaseAnchor = OtherAnchor;

		RepositionRoots();
	}

	void SetActorLocationInSplit(FVector Location, EHazeWorldLinkLevel Split)
	{
		if (Split == BaseAnchor.AnchorLevel)
			SetActorLocation(Location);
		else
			SetActorLocation(Location - OppositeAnchor.ActorLocation + BaseAnchor.ActorLocation);
	}

	FVector GetActorLocationInSplit(EHazeWorldLinkLevel Split)
	{
		if (Split == BaseAnchor.AnchorLevel)
			return ActorLocation;
		else
			return ActorLocation - BaseAnchor.ActorLocation + OppositeAnchor.ActorLocation;
	}

	void RepositionRoots()
	{
		if (BaseAnchor == nullptr)
			OnInitWorldLink();

		FTransform OppositeTransform = FTransform(
			ActorQuat,
			ActorLocation - BaseAnchor.ActorLocation + OppositeAnchor.ActorLocation,
			ActorScale3D,
		);

		if (BaseAnchor.AnchorLevel == EHazeWorldLinkLevel::Fantasy)
		{
			FantasyRoot.WorldTransform = ActorTransform;
			ScifiRoot.WorldTransform = OppositeTransform;
		}
		else
		{
			ScifiRoot.WorldTransform = ActorTransform;
			FantasyRoot.WorldTransform = OppositeTransform;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BaseAnchor = WorldLink::GetClosestAnchor(ActorLocation);
		OppositeAnchor = WorldLink::GetOppositeAnchor(BaseAnchor);

		if (BaseAnchor == nullptr || OppositeAnchor == nullptr)
		{
			Timer::SetTimer(this, n"OnInitWorldLink", 0.00001);
		}
		else
		{
			OnInitWorldLink();
		}

		if (!bFantasyEnabled)
			SetFantasyEnabled(false);
		if (!bScifiEnabled)
			SetScifiEnabled(false);
	}

	UFUNCTION()
	private void OnInitWorldLink()
	{
		BaseAnchor = WorldLink::GetClosestAnchor(ActorLocation);
		OppositeAnchor = WorldLink::GetOppositeAnchor(BaseAnchor);

		FantasyRoot.SetAbsolute(true, true, true);
		ScifiRoot.SetAbsolute(true, true, true);

		RepositionRoots();

		SceneComponent::BindOnSceneComponentMoved(Root, FOnSceneComponentMoved(this, n"OnActorMoved"));
	}

	UFUNCTION()
	private void OnActorMoved(USceneComponent MovedComponent, bool bIsTeleport)
	{
		RepositionRoots();
	}
};