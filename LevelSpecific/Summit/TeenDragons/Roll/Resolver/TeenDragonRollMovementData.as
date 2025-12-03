class UTeenDragonRollMovementData : USteppingMovementData
{
	default DefaultResolverType = UTeenDragonRollMovementResolver;

	UTeenDragonRollSettings RollSettings;
	UTeenDragonRollWallKnockbackSettings DefaultKnockbackSettings;
	UTeenDragonTailGeckoClimbSettings ClimbSettings;

	bool bHasBouncedSinceLanding = false;
	bool bKnockbackIsBlocked = false;
	bool bWantToJump = false;

	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;
		
		auto Owner = Cast<AHazeActor>(MovementComponent.Owner);
		RollSettings = UTeenDragonRollSettings::GetSettings(Owner);
		DefaultKnockbackSettings = UTeenDragonRollWallKnockbackSettings::GetSettings(Owner);
		ClimbSettings = UTeenDragonTailGeckoClimbSettings::GetSettings(Owner);

		bKnockbackIsBlocked = UTeenDragonRollComponent::Get(Owner).KnockBackIsBlocked();
		bHasBouncedSinceLanding = UTeenDragonRollBounceComponent::Get(Owner).bHasBouncedSinceLanding;
		bWantToJump = UPlayerTeenDragonComponent::Get(Owner).bWantToJump;

		return true;
	}

#if EDITOR
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);
		
		const auto Other = Cast<UTeenDragonRollMovementData>(OtherBase);
		RollSettings = Other.RollSettings;
		DefaultKnockbackSettings = Other.DefaultKnockbackSettings;
		ClimbSettings = Other.ClimbSettings;

		bKnockbackIsBlocked = Other.bKnockbackIsBlocked;
		bHasBouncedSinceLanding = Other.bHasBouncedSinceLanding;
	}
#endif
}