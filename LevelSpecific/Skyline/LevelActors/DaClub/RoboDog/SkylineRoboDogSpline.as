class ASkylineRoboDogSpline : ASplineActor
{
	default Spline.EditingSettings.bEnableVisualizeScale = true;
	default Spline.EditingSettings.bEnableVisualizeRoll = true;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};