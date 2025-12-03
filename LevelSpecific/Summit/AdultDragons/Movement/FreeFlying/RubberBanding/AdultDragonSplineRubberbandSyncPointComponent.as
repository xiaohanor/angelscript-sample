UCLASS(NotBlueprintable)
class UAdultDragonSplineRubberBandSyncPointComponent : UAlongSplineComponent
{
	UPROPERTY(EditAnywhere)
	UAdultDragonSplineFollowRubberBandingSettings RubberBandSettings;

#if EDITOR
	void Visualize(const UHazeScriptComponentVisualizer Visualizer) const
	{
		Visualizer.DrawCircle(WorldLocation, 100000, GetVisualizeColor(), 500, ComponentQuat.ForwardVector);
		FString WorldString = RubberBandSettings.PreferredAheadPlayer == EHazePlayer::Mio ? "Preferred Ahead: Mio" : "Preferred Ahead: Zoe";
		Visualizer.DrawWorldString(WorldString, WorldLocation, GetVisualizeColor(), 2, -1, true, true);
	}

	FLinearColor GetVisualizeColor() const
	{
		return FLinearColor(1.00, 0.73, 0.00);
	}

	FString GetVisualName() const
	{
		return f"{Name}";
	}
#endif
};

#if EDITOR
class UAdultDragonSplineRubberBandSyncPointComponentVisualizer : UAlongSplineComponentVisualizer
{
	default VisualizedClass = UAdultDragonSplineRubberBandSyncPointComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		Super::VisualizeComponent(Component);

		const auto ZoneComp = Cast<UAdultDragonSplineRubberBandSyncPointComponent>(Component);
		if(ZoneComp == nullptr)
			return;

		ZoneComp.Visualize(this);	
	}
};
#endif