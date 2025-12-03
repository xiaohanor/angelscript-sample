UCLASS(Abstract)
class AStormChaseFallingObstacleArea : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(VisibleAnywhere)
	TArray<UStormChaseFallingObstacleComponent> FallingComps;

	float TimeWhenActivated = 0;
	bool bIsActive = false;

	UPROPERTY(EditAnywhere)
	ASerpentEventActivator SerpentEvent;

	/** default value is initial radius */
	UPROPERTY(EditAnywhere)
	float ReleaseRadius = 1500;

	/** Amount the radius increases in units per second */
	UPROPERTY(EditAnywhere)
	bool bInstantExpansion = true;

	UPROPERTY(EditAnywhere, meta = (EditCondition="!bInstantExpansion", EditConditionHides))
	float ReleaseRadiusExpansionRate = 10000;

	/** */
	const float VisualizationMaxDuration = 5;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Visual;
	default Visual.SpriteName = "SkullAndBones";
	default Visual.WorldScale3D = FVector(15.0);

	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		float ActiveDuration = Time::GameTimeSeconds % VisualizationMaxDuration;
		Debug::DrawDebugSphere(ActorLocation, ReleaseRadius + ReleaseRadiusExpansionRate * ActiveDuration, 12, FLinearColor::DPink, 50, 0, true);
	}

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface EditorMaterial;

	float TimeWhenStartedVisualizing = 0;

	UPROPERTY(EditAnywhere)
	float VisualizationDuration = 2;

	UPROPERTY(EditAnywhere)
	bool bLoopVisualization = false;

	bool bIsVisualizing = false;

	UFUNCTION(CallInEditor)
	void Visualize()
	{
		TimeWhenStartedVisualizing = Time::GameTimeSeconds;
		bIsVisualizing = true;
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetObstacleCompsInChildren();
		SerpentEvent.OnSerpentEventTriggered.AddUFunction(this, n"OnSerpentEventTriggered");
		ActorTickEnabled = false;
	}

	UFUNCTION()
	private void OnSerpentEventTriggered()
	{
		StartReleasingObstacles();
	}

	UFUNCTION(CallInEditor)
	void GetObstacleCompsInChildren()
	{
		FallingComps.Empty();
		Root.GetChildrenComponentsByClass(UStormChaseFallingObstacleComponent, true, FallingComps);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bool bShouldDeactivateTick = true;
		ReleaseRadius += ReleaseRadiusExpansionRate * DeltaSeconds;
		for (int i = FallingComps.Num() - 1; i >= 0; i--)
		{
			if ((FallingComps[i].Owner.ActorLocation - ActorLocation).Size() < ReleaseRadius)
			{
				FallingComps[i].StartFalling();
				//FallingComps.RemoveAt(i);
			}
			else
			{
				bShouldDeactivateTick = false;
			}
		}

		if (bShouldDeactivateTick)
		{
			ActorTickEnabled = false;
		}
	}

	UFUNCTION()
	void StartReleasingObstacles()
	{
		if (bInstantExpansion)
		{
			for (int i = FallingComps.Num() - 1; i >= 0; i--)
			{
				FallingComps[i].StartFalling();
			}
		}
		else
		{
			ActorTickEnabled = true;
		}
	}
};