event void FOnSummitDarkCaveBallImpact();

class USummitDarkCaveChainedBallResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnSummitDarkCaveBallImpact OnSummitDarkCaveBallImpact;

	UPROPERTY()
	bool bImpactOnlyOnce = false;

	bool bHaveImpacted;

	float HitDurationAllowed = 3;
	float NextAllowedHitTime;

	void OnBallImpact(ASummitDarkCaveChainedBall Ball)
	{
		if (!Ball.HasControl())
			return;
		
		if (bImpactOnlyOnce && bHaveImpacted)
			return;

		if (Time::GameTimeSeconds < NextAllowedHitTime)
			return;

		NextAllowedHitTime = Time::GameTimeSeconds + HitDurationAllowed;
		bHaveImpacted = true;

		CrumbOnBallImpact();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnBallImpact()
	{
		OnSummitDarkCaveBallImpact.Broadcast();
	}
};