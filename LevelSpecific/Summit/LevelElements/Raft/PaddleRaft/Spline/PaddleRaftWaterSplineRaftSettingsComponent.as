class UPaddleRaftWaterSplineRaftSettingsComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Settings")
	UPaddleRaftSettings Settings;

	FSplinePosition SplinePos;

	int opCmp(UPaddleRaftWaterSplineRaftSettingsComponent Other) const
	{
		if(SplinePos.CurrentSplineDistance > Other.SplinePos.CurrentSplineDistance)
			return 1;
		else
			return -1;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		APaddleRaftWaterSpline Spline = Cast<APaddleRaftWaterSpline>(Owner);
		if(Spline == nullptr)
			return;

		SplinePos = Spline.Spline.GetClosestSplinePositionToWorldLocation(WorldLocation);
		WorldLocation = SplinePos.WorldLocation;

		Spline.Modify();
		Spline.RefreshRaftSettingsComponents();
	}
#endif
}