class USkylineFlyingCarBazookaTargetableComponent : UTargetableComponent
{
	UPROPERTY()
	float MinCameraAngle = 15.0;

	const float MaxAngle = 80;

	private bool bPrimary;
	float BecamePrimaryTimeStamp;

	const float LockOnDuration = 0.2;

	float LockOnProgress;
	float LockedOnTimeStamp;

	bool bLockedOn;

	bool bPlayerAimingDown = false;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Targetable::ScoreLookAtAim(Query);

		if (!Query.Result.bPossibleTarget)
			return false;

		ScoreCameraAngle(Query);

		return true;
	}

	void ScoreCameraAngle(FTargetableQuery& Query) const
	{
		FVector CameraToTargetable = Query.TargetableLocation - Query.ViewLocation;
		float Angle = Math::RadiansToDegrees(Query.AimRay.Direction.AngularDistance(CameraToTargetable));
		if (Angle > MinCameraAngle)
			Query.Result.bPossibleTarget = false;

		float AngleScore = 1.0 - (Math::Max(Angle, KINDA_SMALL_NUMBER) / MaxAngle);
		Query.Result.Score += AngleScore;
	}

	void UpdateWidget(UTargetableWidget Widget, FTargetableResult QueryResult) const override
	{
		UFlyingCarBazookaTargetableWidget LockOnWidget = Cast<UFlyingCarBazookaTargetableWidget>(Widget);
		if (LockOnWidget == nullptr)
			return;

		LockOnWidget.SetLockOnProgress(LockOnProgress);
		LockOnWidget.bLockedOn = bLockedOn;

		if (bLockedOn)
			LockOnWidget.LockedOnDuration = Time::GameTimeSeconds - LockedOnTimeStamp;
		else
			LockOnWidget.LockedOnDuration = 0.0;
	}

	void GainPrimaryStatus()
	{
		bPrimary = true;
		BecamePrimaryTimeStamp = Time::GameTimeSeconds;
		LockOnProgress = 0.0;
	}

	void LosePrimaryStatus()
	{
		bPrimary = false;
		bLockedOn = false;
		BecamePrimaryTimeStamp = 0;
		LockOnProgress = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bPrimary)
		{
			// Lock on faster if player is aiming down them sights
			float Multiplier = bPlayerAimingDown ? 1.5 : 1.0;
			float ActivePrimaryTime = (Time::GameTimeSeconds - BecamePrimaryTimeStamp) * Multiplier;
			LockOnProgress = Math::Saturate(ActivePrimaryTime / LockOnDuration);

			if (!bLockedOn && LockOnProgress >= 1.0)
				LockedOn();

			// Eman TODO: Add multiplier based on how in-sight this is?
		}
	}

	private void LockedOn()
	{
		bLockedOn = true;
		LockedOnTimeStamp = Time::GameTimeSeconds;
	}

	bool IsLockedOn() const
	{
		if (!bPrimary)
			return false;

		if (LockOnProgress < 1.0)
			return false;

		return true;
	}

}