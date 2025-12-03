class UBattlefieldHoverboardLevelRubberbandingComponent : UActorComponent
{
	UBattlefieldHoverboardLevelRubberbandingSplineComponent LevelRubberBandSplineComp;
	FSplinePosition SplinePos;

	private float CurrentRubberbandingSpeed;

	float GetRubberbandingSpeed() const property
	{
		return CurrentRubberbandingSpeed;
	}

	void SetRubberbandingSpeed(float NewRubberbandingSpeed) property
	{
		CurrentRubberbandingSpeed = NewRubberbandingSpeed;
	}
};