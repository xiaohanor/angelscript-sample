enum ESkylineBallBossTopLaserSplineID
{
	None,
	Spline1,
	Spline2,
	Spline3,
	Spline4,
	Spline5,
	Spline6,
};

class ASkylineBallBossTopLaserSpline : ASplineActor
{
#if EDITOR
	default Spline.EditingSettings.SplineColor = bRetrace ? ColorDebug::Ruby : ColorDebug::Carrot;
#endif
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditInstanceOnly)
	ESkylineBallBossTopLaserSplineID SplineID;

	UPROPERTY(EditAnywhere)
	float DelayedStartForRotationAlignment = 1.0;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike LaserSpeedTimeLike;
	default LaserSpeedTimeLike.Duration = 1.0;

	UPROPERTY(EditInstanceOnly)
	bool bRetrace = true;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike RetraceLaserSpeedTimeLike;
	default RetraceLaserSpeedTimeLike.Duration = 1.0;
}