class UIslandTurretHackedBehaviour : UBasicBehaviour
{
	UIslandTurretHackComponent HackComp;
	UScifiCopsGunThrowTargetableComponent CopsGunsThrowTargetableComp;
	UIslandTurretSettings TurretSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		CopsGunsThrowTargetableComp = UScifiCopsGunThrowTargetableComponent::Get(Owner);
		HackComp = UIslandTurretHackComponent::Get(Owner);
		TurretSettings = UIslandTurretSettings::GetSettings(Owner);
	}

	bool IsFacingAway() const
	{
		FVector ToTarget = (Game::Mio.ActorCenterLocation - Owner.ActorCenterLocation);
		ToTarget.Z = 0.0;
		return Owner.ActorForwardVector.DotProduct(ToTarget.GetSafeNormal()) < 0.707;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!HackComp.bEnabled)
			return false;
		if(!HackComp.IsHacked())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!HackComp.bEnabled)
			return true;
		if(!HackComp.IsHacked())
			return true;
		if(ActiveDuration > TurretSettings.HackedDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		HackComp.Secure();
	}
}
