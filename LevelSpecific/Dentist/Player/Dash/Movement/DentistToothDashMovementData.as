class UDentistToothDashMovementData : USweepingMovementData
{
	access Protected = protected, UDentistToothDashMovementResolver (inherited);

	default DefaultResolverType = UDentistToothDashMovementResolver;

	access:Protected
	float GroundHitRestitution = -1;

	access:Protected
	float BackflipDurationMultiplier = -1;

	access:Protected
	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		const auto DashSettings = UDentistToothDashSettings::GetSettings(MovementComponent.HazeOwner);

		if(DashSettings.bBounceOnHitBouncyGround)
			GroundHitRestitution = DashSettings.GroundBounceRestitution;
		else
			GroundHitRestitution = -1;

		BackflipDurationMultiplier = DashSettings.BackflipDurationMultiplier;

		return true;
	}

#if EDITOR
	access:Protected
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);

		const auto Other = Cast<UDentistToothDashMovementData>(OtherBase);
		GroundHitRestitution = Other.GroundHitRestitution;
		BackflipDurationMultiplier = Other.BackflipDurationMultiplier;
	}
#endif
};