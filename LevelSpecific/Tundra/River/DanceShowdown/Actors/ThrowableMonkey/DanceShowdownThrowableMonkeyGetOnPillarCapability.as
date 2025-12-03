class UDanceShowdownThrowableMonkeyGetOnPillarCapability : UDanceShowdownThrowableMonkeyChildCapability
{
	float JumpDuration = 0.5;
	float HorizontalOffset = 500;
	float JumpHeight = 30;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Monkey.State != EThrowableMonkeyState::MovingToPillar)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Monkey.State != EThrowableMonkeyState::MovingToPillar)
			return true;

		if(ActiveDuration >= JumpDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Monkey.RemoveActorVisualsBlock(Monkey);
		Monkey.SetActorRelativeLocation(FVector(-HorizontalOffset, 0, -JumpHeight));
		Monkey.PlaySlotAnimation(Monkey.JumpAnim);
		Monkey.SetActorHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(Monkey.State == EThrowableMonkeyState::MovingToPillar)
		{
			Monkey.State = EThrowableMonkeyState::OnPillar;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector NewLocation = Monkey.ActorRelativeLocation;
		NewLocation.X = Math::FInterpConstantTo(NewLocation.X, 0, DeltaTime, HorizontalOffset * (1 / JumpDuration));
		NewLocation.Z = -JumpHeight + (Monkey.JumpHeightCurve.GetFloatValue(Math::Saturate(ActiveDuration / JumpDuration))) * JumpHeight;
		Monkey.SetActorRelativeLocation(NewLocation);
	}
};