class UGoatLaserEyesAutoAimComponent : UAutoAimTargetComponent
{
	default TargetableCategory = n"GoatLaserEyes";
	default AutoAimMaxAngle = 8.0;

	UPROPERTY(EditAnywhere)
	float Range = 2000.0;

	UPROPERTY(EditAnywhere)
	bool bTestCollision = true;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Targetable::ApplyVisibleRange(Query, Range);
		Targetable::ScoreLookAtAim(Query);

		if (bTestCollision)
			return Targetable::RequireNotOccludedFromCamera(Query);

		return true;
	}
}