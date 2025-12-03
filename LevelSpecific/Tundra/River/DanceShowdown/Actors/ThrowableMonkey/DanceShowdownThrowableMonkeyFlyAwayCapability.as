class UDanceShowdownThrowableMonkeyFlyAwayCapability : UDanceShowdownThrowableMonkeyChildCapability
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Monkey.State != EThrowableMonkeyState::ThrownOff)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Monkey.State != EThrowableMonkeyState::ThrownOff)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Monkey.PlaySlotAnimation(Monkey.JumpAnim);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector ToTarget = GetTargetFlyAwayLocation(Monkey.FlyAwayDirection) - Monkey.ActorLocation;
		Monkey.AddActorWorldOffset(ToTarget.GetSafeNormal() * DeltaTime * Monkey.FlyAwaySpeed);

		const float Yaw = Monkey.FlyAwayDirection * -Monkey.FlyAwayRotationSpeed * DeltaTime;

		Owner.AddActorLocalRotation(FRotator(0, Yaw, 0));

		if(ToTarget.Size() < 100)
		{
			Monkey.OnFinishedRemoving();
		}
	}

	FVector GetTargetFlyAwayLocation(float Direction) const
	{
		return Monkey.GetTargetHeadLocation() + Monkey.TargetPlayer.Owner.ActorRightVector * Direction * 700.0 + FVector::UpVector * 300.0;
	}
};