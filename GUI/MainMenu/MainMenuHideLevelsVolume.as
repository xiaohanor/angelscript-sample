class AMainMenuHideLevelsVolume : AHazeActor
{
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent BoxComponent;
	default BoxComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default BoxComponent.BoxExtent = FVector(500, 500, 500);
	default BoxComponent.LineThickness = 50.0;
	default BoxComponent.ShapeColor = FColor::Emerald;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targets")
	TArray<TSoftObjectPtr<UWorld>> TargetLevels;

	bool bLevelsVisible = true;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bool bCameraInsideVolume = false;

		auto FirstView = SceneView::GetViewPointForPosition(EHazeSplitScreenPosition::FirstPlayer);
		if (FirstView != nullptr && BoxComponent.IsPointInside(FirstView.ViewLocation))
			bCameraInsideVolume = true;

		if (bCameraInsideVolume)
		{
			if (bLevelsVisible)
			{
				for (auto Target : TargetLevels)
				{
					if (Target.Get() == nullptr)
						continue;
					SceneView::SetLevelRenderedForAnyView(Target, false);
				}
				bLevelsVisible = false;
			}
		}
		else
		{
			if (!bLevelsVisible)
			{
				for (auto Target : TargetLevels)
				{
					if (Target.Get() == nullptr)
						continue;
					SceneView::SetLevelRenderedForAnyView(Target, true);
				}
				bLevelsVisible = true;
			}
		}
	}
}