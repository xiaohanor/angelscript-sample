class UIslandTurretExposeHackBehaviour : UBasicBehaviour
{
	UIslandTurretHackComponent HackComp;
	UScifiCopsGunThrowTargetableComponent CopsGunsThrowTargetableComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		CopsGunsThrowTargetableComp = UScifiCopsGunThrowTargetableComponent::Get(Owner);
		HackComp = UIslandTurretHackComponent::Get(Owner);
		CopsGunsThrowTargetableComp.DisableForPlayer(Game::Mio, this);
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
		if(HackComp.IsHacked())
			return false;
		if(!IsFacingAway())
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
		if(HackComp.IsHacked())
			return true;
		if(!IsFacingAway())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		CopsGunsThrowTargetableComp.EnableForPlayer(Game::Mio, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		CopsGunsThrowTargetableComp.DisableForPlayer(Game::Mio, this);
	}
}
