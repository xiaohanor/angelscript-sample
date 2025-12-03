class UDanceShowdownThrowableMonkeyThrowCapability : UDanceShowdownThrowableMonkeyChildCapability
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Monkey.State != EThrowableMonkeyState::Grabbed && Monkey.State != EThrowableMonkeyState::Thrown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Monkey.State != EThrowableMonkeyState::Grabbed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Monkey.PlaySlotAnimation(Monkey.HandAnim);
		Monkey.AttachToComponent(DanceShowdown::GetManager().MonkeyKing.SkeletalMesh, Monkey.TargetPlayer.Player.IsMio() ? n"LeftHand" : n"RightHand");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.DetachFromActor();
		Monkey.State = EThrowableMonkeyState::MovingToPlayer;
	}
};