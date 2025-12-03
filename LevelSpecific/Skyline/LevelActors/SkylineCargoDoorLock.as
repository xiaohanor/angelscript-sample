class ASkylineCargoDoorLock : AHazeActor
{
	UFUNCTION()
	void EffectEvent_OnStartMoving()
	{
		USkylineCargoDoorLockEventHandler::Trigger_OnStartMoving(this);
	}

	UFUNCTION()
	void EffectEvent_OnStopMoving()
	{
		USkylineCargoDoorLockEventHandler::Trigger_OnStopMoving(this);
	}

	UFUNCTION()
	void EffectEvent_OnConstrainHitLowAlpha(float HitStrength)
	{
		FSkylineCargoDoorLockEventConstrainHit ConstrainHitStrength;
		ConstrainHitStrength.HitStrength = HitStrength;
		USkylineCargoDoorLockEventHandler::Trigger_OnConstrainHitLowAlpha(this, ConstrainHitStrength);
	}

	UFUNCTION()
	void EffectEvent_OnConstrainHitHighAlpha(float HitStrength)
	{
		FSkylineCargoDoorLockEventConstrainHit ConstrainHitStrength;
		ConstrainHitStrength.HitStrength = HitStrength;
		USkylineCargoDoorLockEventHandler::Trigger_OnConstrainHitHighAlpha(this, ConstrainHitStrength);
	}

	UFUNCTION()
	void EffectEvent_OnGravityWhipGrabbed()
	{
		USkylineCargoDoorLockEventHandler::Trigger_OnGravityWhipGrabbed(this);
	}		

	UFUNCTION()
	void EffectEvent_OnGravityWhipReleased()
	{
		USkylineCargoDoorLockEventHandler::Trigger_OnGravityWhipReleased(this);
	}	
};