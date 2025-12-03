class UDanceShowdownThrowableMonkeyInAirCapability : UDanceShowdownThrowableMonkeyChildCapability
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Monkey.State != EThrowableMonkeyState::MovingToPlayer)
			return false;

		if(Monkey.TargetPlayer == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Monkey.State != EThrowableMonkeyState::MovingToPlayer)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Monkey.PlaySlotAnimation(Monkey.InAirAnim);
		Owner.SetActorRotation((Monkey.GetTargetHeadLocation() - Owner.ActorLocation).ToOrientationRotator());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector ToPlayer = Monkey.GetTargetHeadLocation() - Owner.ActorLocation;
		Owner.AddActorWorldOffset(ToPlayer.GetSafeNormal() * DeltaTime * Monkey.FlyToPlayerSpeed);

		if(ToPlayer.Size() < 150)
			Monkey.State = EThrowableMonkeyState::OnFace;
	}
};