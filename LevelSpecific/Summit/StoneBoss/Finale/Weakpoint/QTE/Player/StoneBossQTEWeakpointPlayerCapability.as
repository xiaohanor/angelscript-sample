class UStoneBossQTEWeakpointPlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::BeforeMovement;

	default DebugCategory = n"Weakpoint";

	UStoneBossQTEWeakpointPlayerComponent WeakpointComp;
	UDragonSwordUserComponent DragonSwordComp;
	bool bWasInsideStabWindow;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeakpointComp = UStoneBossQTEWeakpointPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (WeakpointComp.Weakpoint == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (WeakpointComp.Weakpoint == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (HasControl())
			WeakpointComp.CrumbApplyInstigatedState(EPlayerStoneBossQTEWeakpointState::Default, this, EInstigatePriority::Low);

		WeakpointComp.DrawBackAlpha = 0.0;

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
	}
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (HasControl())
			WeakpointComp.CrumbClearInstigatedState(this);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.RequestLocomotion(n"DragonSwordWeakPoint", this);
		if (WeakpointComp.bIsInsideStabWindow && !bWasInsideStabWindow)
		{
			if (WeakpointComp.Weakpoint.CurrentHealth <= 0)
			{
				WeakpointComp.Weakpoint.DestroyWeakpoint();
			}
		}
		if (!WeakpointComp.bIsInsideStabWindow && bWasInsideStabWindow)
		{
			if (DragonSwordComp == nullptr)
				DragonSwordComp = UDragonSwordUserComponent::Get(Player);

			FStoneBeastWeakpointSwordRetractParams Params;
			Params.Player = Player;
			Params.SwordLocation = DragonSwordComp.Weapon.ActorLocation;
			UStoneBossQTEWeakpointPlayerEffectHandler::Trigger_OnWeakpointSwordRetract(Player, Params);
			//Print(f"SWORD RETRACTED", 5, FLinearColor::Yellow);
		}

		bWasInsideStabWindow = WeakpointComp.bIsInsideStabWindow;
	}
};