class UJetskiMovementData : UFloatingMovementData
{
	access Protected = protected, UJetskiMovementResolver (inherited);

	default DefaultResolverType = UJetskiMovementResolver;

	access:Protected
	bool bClamp;

	access:Protected
	FTransform SplineTransform;

	access:Protected
	EJetskiJosefVolumeDeathFromWallImpactsMode DeathFromWallImpactsMode;

	access:Protected
	bool bIsJumpingFromUnderwater;

	access:Protected
	bool bDriverIsAlive = true;

	access:Protected
	bool bCanDieFromWallImpacts = true;

	access:Protected
	float WallImpactDeathJetskiAngleMax;

	access:Protected
	float WallImpactDeathSplineAngleMax;

	access:Protected
	float MinForwardSpeedToDie;

	access:Protected
	float CeilingImpactDeathAngleMax;

	access:Protected
	bool bAllowAligningWithCeiling;

	access:Protected
	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp = FVector::ZeroVector) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		auto Jetski = Cast<AJetski>(MovementComponent.Owner);

		bClamp = Jetski.Settings.bSplineClamp && Jetski.Settings.SteeringMode == EJetskiSteeringMode::Spline;

		SplineTransform = Jetski.GetSplineTransform();

		DeathFromWallImpactsMode = EJetskiJosefVolumeDeathFromWallImpactsMode::Default;
		if(!Jetski.JosefVolumes.IsEmpty())
			DeathFromWallImpactsMode = Jetski.JosefVolumes.Last().DeathFromWallImpactsMode;

		bIsJumpingFromUnderwater = Jetski.bIsJumpingFromUnderwater;

		bDriverIsAlive = Jetski.Driver != nullptr && !Jetski.Driver.IsPlayerDead();

		bCanDieFromWallImpacts = CanDieFromImpacts();

		WallImpactDeathJetskiAngleMax = Jetski.Settings.WallImpactDeathJetskiAngleMax;
		WallImpactDeathSplineAngleMax = Jetski.Settings.WallImpactDeathSplineAngleMax;
		MinForwardSpeedToDie = Jetski.Settings.MinForwardSpeedToDie;

		CeilingImpactDeathAngleMax = Jetski.Settings.CeilingImpactDeathAngleMax;

		bAllowAligningWithCeiling = false;

		return true;
	}

	private bool CanDieFromImpacts() const
	{
		switch(DeathFromWallImpactsMode)
		{
			case EJetskiJosefVolumeDeathFromWallImpactsMode::OnlyDieWhenJumpingFromUnderwater:
			{
				if(!bIsJumpingFromUnderwater)
					return false;

				return true;
			}

			case EJetskiJosefVolumeDeathFromWallImpactsMode::NeverDie:
				return false;

			case EJetskiJosefVolumeDeathFromWallImpactsMode::Default:
				return true;
		}
	}

	void AllowAligningWithCeiling()
	{
		bAllowAligningWithCeiling = true;
	}

#if EDITOR
	access:Protected
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);
		
		const UJetskiMovementData Other = Cast<UJetskiMovementData>(OtherBase);
		if(Other == nullptr)
			return;

		bClamp = Other.bClamp;
		SplineTransform = Other.SplineTransform;
		DeathFromWallImpactsMode = Other.DeathFromWallImpactsMode;
		bIsJumpingFromUnderwater = Other.bIsJumpingFromUnderwater;
		bDriverIsAlive = Other.bDriverIsAlive;
		bCanDieFromWallImpacts = Other.bCanDieFromWallImpacts;
		WallImpactDeathJetskiAngleMax = Other.WallImpactDeathJetskiAngleMax;
		WallImpactDeathSplineAngleMax = Other.WallImpactDeathSplineAngleMax;
		MinForwardSpeedToDie = Other.MinForwardSpeedToDie;
		CeilingImpactDeathAngleMax = Other.CeilingImpactDeathAngleMax;
		bAllowAligningWithCeiling = Other.bAllowAligningWithCeiling;
	}
#endif
}