enum EPrisonStealthGuardSectionType
{
	FollowSpline,
	StandStill
}

enum EPrisonStealthGuardSplineDir
{
	Forward,
	Reverse
}

struct FPrisonStealthGuardSection
{
	UPROPERTY(EditAnywhere)
	EPrisonStealthGuardSectionType SectionType;

	/**
	 * Follow Spline
	 */

	UPROPERTY(EditAnywhere, meta = (EditCondition = "SectionType == EPrisonStealthGuardSectionType::FollowSpline", EditConditionHides))
	TSoftObjectPtr<ASplineActor> SplineToFollow;

	// Forward or back. Put two sections in a row to get a back and forth behaviour.
	UPROPERTY(EditAnywhere, meta = (EditCondition = "SectionType == EPrisonStealthGuardSectionType::FollowSpline", EditConditionHides))
	EPrisonStealthGuardSplineDir Direction;

	bool HasValidSpline() const
	{
		return SplineToFollow.IsValid() && SplineToFollow.Get().Spline != nullptr;
	}

	UHazeSplineComponent GetSpline() const
	{
		check(HasValidSpline());
		return SplineToFollow.Get().Spline;
	}

	/**
	 * Stand Still
	 */

	UPROPERTY(EditAnywhere, meta = (EditCondition = "SectionType == EPrisonStealthGuardSectionType::StandStill", EditConditionHides))
	float Duration = 5.0;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "SectionType == EPrisonStealthGuardSectionType::StandStill", EditConditionHides))
	float StartTurningDuringStandStillAlpha = 0.8;

	// Manually set what direction the guard should look in, instead of just using the last rotation from the previous section. Enables swiveling.
	UPROPERTY(EditAnywhere, meta = (EditCondition = "SectionType == EPrisonStealthGuardSectionType::StandStill", EditConditionHides))
	bool bSetWorldYaw = false;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "SectionType == EPrisonStealthGuardSectionType::StandStill && bSetWorldYaw", EditConditionHides))
	float WorldYaw;

	// Filip TODO: Allow without WorldYaw too? Slightly more complicated
	UPROPERTY(EditAnywhere, meta = (EditCondition = "SectionType == EPrisonStealthGuardSectionType::StandStill && bSetWorldYaw", EditConditionHides))
	bool bSwivelBackAndForth = false;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "SectionType == EPrisonStealthGuardSectionType::StandStill && bSetWorldYaw && bSwivelBackAndForth", EditConditionHides, ClampMin = "10", ClampMax = "170"))
	float SwivelAmount = 30.0;

	/**
	 * Debug
	 */

	UPROPERTY(EditAnywhere)
	bool bDebugDraw = true;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "bDebugDraw"))
	FLinearColor DebugColor = FLinearColor::White;
}

enum EPrisonStealthGuardState
{
	Enabled,
	Disabled,
	Invisible
}