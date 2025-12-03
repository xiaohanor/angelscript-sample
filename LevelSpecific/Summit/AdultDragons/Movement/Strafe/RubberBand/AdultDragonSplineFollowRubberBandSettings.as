
class UAdultDragonSplineFollowRubberBandingSettings : UHazeComposableSettings
{
	/** The distance between front and back player */
	UPROPERTY()
	float IdealPlayerDistance = 5500.0;

	/** At this distance between the players, the max of the slow and increase multipliers will kick in. */
	UPROPERTY()
	float MaxDistance = 6000;

	/** If the distance is less than this, the rubber banding is ignored */
	UPROPERTY()
	float MinDistance = 5000.0;

	/** This multiplier is applied between 1 and this at the max distance */
	UPROPERTY()
	float MaxBehindSpeedMultiplier = 1.4;

	/** This multiplier is applied between 1 and this at the max distance */
	UPROPERTY()
	float MaxAHeadSpeedMultiplier = 0.75;

	/** What player do we prefer being a head of the other */
	UPROPERTY()
	EHazePlayer PreferredAheadPlayer = EHazePlayer::Zoe;
}