class UDentistToothMovementData : USteppingMovementData
{
	access Protected = protected, UDentistToothMovementResolver (inherited);

	default DefaultResolverType = UDentistToothMovementResolver;

	access:Protected
	bool bUnstableEdgeIsUnwalkable = false;;

	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		bUnstableEdgeIsUnwalkable = false;

		return true;
	}

#if EDITOR
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);

		const auto Other = Cast<UDentistToothMovementData>(OtherBase);
		bUnstableEdgeIsUnwalkable = Other.bUnstableEdgeIsUnwalkable;
	}
#endif

	void ApplyUnstableEdgeIsUnwalkable()
	{
		bUnstableEdgeIsUnwalkable = true;
	}
};