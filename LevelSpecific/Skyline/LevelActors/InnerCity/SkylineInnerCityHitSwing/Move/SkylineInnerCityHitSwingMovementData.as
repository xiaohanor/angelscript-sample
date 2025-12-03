class USkylineInnerCityHitSwingMovementData : USweepingMovementData
{
	access Protected = protected, USkylineInnerCityHitSwingResolver (inherited);
	
	default DefaultResolverType = USkylineInnerCityHitSwingResolver;

	access:Protected
	FVector UsedMoveClampPlaneNormal = FVector::UpVector;

	access:Protected
	bool bShouldClampToPlane = true;

	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		// Store some values from the actor
		const ASkylineInnerCityHitSwing HitSwing = Cast<ASkylineInnerCityHitSwing>(MovementComponent.Owner);
		SetMoveClampPlaneNormal(HitSwing.ActorUpVector);

		return true;
	}

#if EDITOR
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);
		auto Other = Cast<USkylineInnerCityHitSwingMovementData>(OtherBase);
		UsedMoveClampPlaneNormal = Other.UsedMoveClampPlaneNormal;
		bShouldClampToPlane = Other.bShouldClampToPlane;
	}
#endif

	void SetMoveClampPlaneNormal(FVector NewUp)
	{
		check(!NewUp.ContainsNaN());
		check(NewUp.Size() > KINDA_SMALL_NUMBER);

		UsedMoveClampPlaneNormal = NewUp;
	}

	void SetIsClampedToPlane(bool bNewIsClamped)
	{
		bShouldClampToPlane = bNewIsClamped;
	}

}
