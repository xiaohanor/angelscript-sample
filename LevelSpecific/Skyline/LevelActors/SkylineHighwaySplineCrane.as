class ASkylineHighwaySplineCrane : AHazeActor
{
	UFUNCTION()
	void EffectEvent_OnStartMoving()
	{
		USkylineHighwaySplineCraneEventHandler::Trigger_OnStartMoving(this);
	}

	UFUNCTION()
	void EffectEvent_OnStopMoving()
	{
		USkylineHighwaySplineCraneEventHandler::Trigger_OnStopMoving(this);
	}

	UFUNCTION()
	void EffectEvent_OnConstrainHitLowAlpha(float HitStrength)
	{
		FSkylineHighwaySplineCraneConstrainHit ConstrainHitStrength;
		ConstrainHitStrength.HitStrength = HitStrength;		
		USkylineHighwaySplineCraneEventHandler::Trigger_OnConstrainHitLowAlpha(this, ConstrainHitStrength);
	}

	UFUNCTION()
	void EffectEvent_OnConstrainHitHighAlpha(float HitStrength)
	{
		FSkylineHighwaySplineCraneConstrainHit ConstrainHitStrength;
		ConstrainHitStrength.HitStrength = HitStrength;		
		USkylineHighwaySplineCraneEventHandler::Trigger_OnConstrainHitHighAlpha(this, ConstrainHitStrength);
	}

	UFUNCTION()
	void EffectEvent_OnGravityWhipGrabbed()
	{
		USkylineHighwaySplineCraneEventHandler::Trigger_OnGravityWhipGrabbed(this);
	}		

	UFUNCTION()
	void EffectEvent_OnGravityWhipReleased()
	{
		USkylineHighwaySplineCraneEventHandler::Trigger_OnGravityWhipReleased(this);
	}		
};