struct FCameraLookTowardsSplineSettings
{
	/**
	 * How long we wait after player input before we start reverting to the spline direction.
	 */
	UPROPERTY(EditAnywhere)
	float ReturnDelay = 1.0;
	
	UPROPERTY(EditAnywhere)
	float LerpDuration = 1.5;

	UPROPERTY(EditAnywhere)
	float LookAheadDistance = 200;

	UPROPERTY(EditAnywhere)
	float EaseInOutExponent = 2;

	UPROPERTY(EditAnywhere)
	ECameraLookTowardsSplineDirection Direction = ECameraLookTowardsSplineDirection::Forward;

	UPROPERTY(EditAnywhere)
	bool bOnlyTriggerIfCameraFacingInDirection = true;
};

enum ECameraLookTowardsSplineDirection
{
	// Only rotate towards the splines forward direction.
	Forward,

	// Only rotate towards the splines back direction.
	Back,

	// Rotate towards the direction closest to the input cameras forward
	Closest,
};

struct FCameraLookTowardsSplineData
{
	UHazeSplineComponent Spline;
	FCameraLookTowardsSplineSettings Settings;
};

UCLASS(NotBlueprintable, NotPlaceable)
class UCameraLookTowardsSplineComponent : UActorComponent
{
	access Internal = private, ACameraLookTowardsSplineActor;

	access:Internal
	TInstigated<FCameraLookTowardsSplineData> SplineData;

	void Apply(FCameraLookTowardsSplineData InSplineData, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		SplineData.Apply(InSplineData, Instigator, Priority);
	}
	
	void Clear(FInstigator Instigator)
	{
		SplineData.Clear(Instigator);
	}

	bool HasSplineToFollow() const
	{
		if(SplineData.IsDefaultValue())
			return false;

		return SplineData.Get().Spline != nullptr;
	}

	UHazeSplineComponent GetSpline() const
	{
		if(!HasSplineToFollow())
			return nullptr;

		return SplineData.Get().Spline;
	}

	FCameraLookTowardsSplineSettings GetSettings() const
	{
		if(!HasSplineToFollow())
			return FCameraLookTowardsSplineSettings();

		return SplineData.Get().Settings;
	}
};