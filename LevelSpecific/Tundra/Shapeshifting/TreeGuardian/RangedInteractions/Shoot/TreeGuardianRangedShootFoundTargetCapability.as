class UTundraPlayerTreeGuardianRangedShootFoundTargetCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerAimingComponent AimComp;
	UTundraPlayerTreeGuardianComponent TreeGuardianComp;
	UTundraPlayerTreeGuardianRangedInteractionCrosshairWidget Crosshair;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraTreeGuardianRangedShootAimActivatedParams& Params) const
	{
		if(!AimComp.IsAiming(n"RangedShoot"))
			return false;

		FAimingResult Result = AimComp.GetAimingTarget(n"RangedShoot");
		if(Result.AutoAimTarget == nullptr)
			return false;

		Params.Targetable = Cast<UTundraTreeGuardianRangedShootTargetable>(Result.AutoAimTarget);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!AimComp.IsAiming(n"RangedShoot"))
			return true;

		FAimingResult Result = AimComp.GetAimingTarget(n"RangedShoot");
		if(Result.AutoAimTarget == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraTreeGuardianRangedShootAimActivatedParams Params)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
}

struct FTundraTreeGuardianRangedShootAimActivatedParams
{
	UPROPERTY()
	UTundraTreeGuardianRangedShootTargetable Targetable;
}