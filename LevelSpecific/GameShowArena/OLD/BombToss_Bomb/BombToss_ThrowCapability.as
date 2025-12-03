class UBombTossThrowCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"BombToss");
	default CapabilityTags.Add(n"BombTossCatch");

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 89;

	UBombTossPlayerComponent BombTossPlayerComponent;
	UPlayerAimingComponent PlayerAimingComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BombTossPlayerComponent = UBombTossPlayerComponent::Get(Owner);
		PlayerAimingComponent = UPlayerAimingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		if (BombTossPlayerComponent.CurrentBombToss == nullptr)
			return false;

		if (Time::GetGameTimeSince(BombTossPlayerComponent.CurrentBombToss.TimeOfLastChangeToIsThrown) < BombTossPlayerComponent.CurrentBombToss.CooldownToThrowAfterCatching)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration <= 0.4)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PrintToScreen("Throw!", 2.0, FLinearColor::Green);

		Player.BlockCapabilities(n"BombTossCatch", this);
		BombTossPlayerComponent.ThrewBomb();

		FVector Dir;
		if (!BombTossPlayerComponent.bInSideScroller)
			Dir = (Player.ViewRotation.ForwardVector + FVector::UpVector) * 0.5;
		else
			Dir = (BombTossPlayerComponent.GetSideScrollerDirection() + FVector::UpVector) * 0.5;

		BombTossPlayerComponent.Launch(Dir * Math::Sqrt(Player.GetDistanceTo(Player.OtherPlayer) * BombTossPlayerComponent.BombTossBomb.Gravity) * 1.4, nullptr);
		// Play ThrowAnimation
		Player.PlayOverrideAnimation(FHazeAnimationDelegate(), BombTossPlayerComponent.ThrowAnimation, BombTossPlayerComponent.BoneFilter);

		// Spawn VFX
		Niagara::SpawnOneShotNiagaraSystemAttached(BombTossPlayerComponent.ThrowVFX, Player.Mesh, n"RightAttach");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(n"BombTossCatch", this);
	}
}