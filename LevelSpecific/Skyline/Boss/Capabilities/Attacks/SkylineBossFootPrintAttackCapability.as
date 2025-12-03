struct FSkylineBossFootPrintAttackActivateParams
{
	ASkylineBossLeg LastLiftedLeg;
	FVector Location;
	FRotator Rotation;
};

class USkylineBossFootPrintAttackCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossAttack);
	default CapabilityTags.Add(SkylineBossTags::SkylineBossFootPrintAttack);

	USkylineBossFootStompComponent FootStompComponent;
	ASkylineBossLeg LastLiftedLeg;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		FootStompComponent = Boss.FootStompComponent;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBossFootPrintAttackActivateParams& Params) const
	{
		if (LastLiftedLeg == FootStompComponent.LiftedLeg)
			return false;

		Params.LastLiftedLeg = FootStompComponent.LiftedLeg;
		FootStompComponent.LiftedLeg.GetFootLocationAndRotation(Params.Location, Params.Rotation);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBossFootPrintAttackActivateParams Params)
	{
		LastLiftedLeg = Params.LastLiftedLeg;

		SpawnActor(
			FootStompComponent.ImpactClass,
			Params.Location,
			Params.Rotation
		);
	}
}