event void FTundraRiverBridgeEvent();
event void FTundraRiverBridgeUpdateEvent(float Progress);

class ATundra_River_BridgeObstacles : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent SeedMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent GrowScene;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent GrowSceneHidden;

	UPROPERTY(EditDefaultsOnly)
	bool bIsCeiling = false;

	UPROPERTY()
	FHazeTimeLike GrowAnimation;
	default GrowAnimation.Duration = 1;
	default GrowAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default GrowAnimation.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY()
	FTundraRiverBridgeEvent OnGrowAnimationStartGrowing;
	UPROPERTY()
	FTundraRiverBridgeEvent OnGrowAnimationStartShrinking;
	UPROPERTY()
	FTundraRiverBridgeEvent OnGrowAnimationReachedEnd;
	UPROPERTY()
	FTundraRiverBridgeEvent OnGrowAnimationReachedStart;
	UPROPERTY()
	FTundraRiverBridgeUpdateEvent OnGrowAnimationUpdate;

	bool bCollisionEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GrowAnimation.BindUpdate(this, n"TL_GrowAnimationUpdate");
		GrowAnimation.BindFinished(this, n"TL_GrowAnimationFinished");
		GrowScene.RelativeScale3D = bIsCeiling ? FVector(1, 1, 0.15) : FVector(0.15, 1, 1);
		GrowAnimation.PlayRate = 3;
		SetGrowSceneChildrenVisibility(true);
	}

	UFUNCTION()
	private void TL_GrowAnimationUpdate(float CurrentValue)
	{
		float InternalValue = Math::Clamp(CurrentValue, 0.15, 1);
		OnGrowAnimationUpdate.Broadcast(CurrentValue);
		GrowScene.RelativeScale3D = bIsCeiling ? FVector(1, 1, InternalValue) : FVector(InternalValue, 1, 1);

		if(CurrentValue >= 0.5 && !bCollisionEnabled)
		{
				SetGrowSceneChildrenCollision(true);
		}
	}

	UFUNCTION()
	private void TL_GrowAnimationFinished()
	{
		if(GrowAnimation.GetPosition() > 0.5)
		{
			OnGrowAnimationReachedEnd.Broadcast();
		}
		else
		{
			OnGrowAnimationReachedStart.Broadcast();
			//SetGrowSceneChildrenVisibility(false);
			SetGrowSceneChildrenCollision(false);
		}
	}

	UFUNCTION()
	void Grow()
	{
		if(GrowAnimation.GetPosition() < 1.0)
		{
			//SetGrowSceneChildrenVisibility(true);
			GrowAnimation.Play();
			OnGrowAnimationStartGrowing.Broadcast();
		}
	}

	UFUNCTION()
	void Shrink()
	{
		if(GrowAnimation.GetPosition() > 0.0)
		{
			GrowAnimation.Reverse();
			OnGrowAnimationStartShrinking.Broadcast();
		}
		
	}

	UFUNCTION()
	void SetGrowSceneChildrenVisibility(bool bEnable)
	{
		TArray<USceneComponent> GrowSceneChildren;
		GrowScene.GetChildrenComponents(false, GrowSceneChildren);

		if(GrowSceneChildren.IsEmpty())
			return;

		int NumGrowSceneChildren = GrowScene.GetNumChildrenComponents();

		for(int i = 0; i < NumGrowSceneChildren; i++)
		{
			if(GrowSceneChildren[i] == nullptr)
				break;

			GrowSceneChildren[i].SetHiddenInGame(!bEnable);
		}
	}

	UFUNCTION()
	void SetGrowSceneChildrenCollision(bool bEnable)
	{
		TArray<UStaticMeshComponent> GrowSceneChildren;
		GrowSceneHidden.GetChildrenComponentsByClass(UStaticMeshComponent, false, GrowSceneChildren);

		if(GrowSceneChildren.IsEmpty())
			return;

		int NumGrowSceneChildren = GrowSceneHidden.GetNumChildrenComponents();

		for(int i = 0; i < NumGrowSceneChildren; i++)
		{
			if(GrowSceneChildren[i] == nullptr)
				break;

			GrowSceneChildren[i].CollisionEnabled = bEnable ? ECollisionEnabled::QueryAndPhysics : ECollisionEnabled::NoCollision;
		}
		bCollisionEnabled = bEnable;
	}
};