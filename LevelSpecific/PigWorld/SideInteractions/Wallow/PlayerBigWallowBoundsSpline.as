class APlayerBigWallowBoundsSpline : ASplineActor
{
	default Spline.EditingSettings.SplineColor = ColorDebug::Brown;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	float LongestRadius = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (FHazeSplinePoint Point : Spline.SplinePoints)
		{
			float RadiusIsh = Point.RelativeLocation.Size();
			if (RadiusIsh > LongestRadius)
				LongestRadius = RadiusIsh;
		}
	}

	bool IsInsideBounds(AHazePlayerCharacter Player) const
	{
		FTransform ClosestBoundsTransform = Spline.GetClosestSplineWorldTransformToWorldLocation(Player.ActorCenterLocation);
		FVector Delta = ClosestBoundsTransform.Location - Player.ActorCenterLocation;
		return ClosestBoundsTransform.Rotation.RightVector.DotProduct(Delta) > 0.0;
	}
};