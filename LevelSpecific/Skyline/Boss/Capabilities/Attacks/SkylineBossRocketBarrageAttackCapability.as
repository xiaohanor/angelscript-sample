struct FSkylineBossRocketBarrageAttackActivateParams
{
	AHazeActor Target;
};

class USkylineBossRocketBarrageAttackCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossAttack);

	USkylineBossRocketBarrageComponent RocketBarrageComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		RocketBarrageComp = USkylineBossRocketBarrageComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBossRocketBarrageAttackActivateParams& Params) const
	{
		if (Boss.GetPhase() != ESkylineBossPhase::Second)
			return false;

		if(Boss.GetStateActiveDuration() < 6)
			return false;

		if (!RocketBarrageComp.CanSetTarget())
			return false;

		if (Boss.LookAtTarget.Get() == nullptr)
			return false;

		Params.Target = Boss.LookAtTarget.Get();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!RocketBarrageComp.IsLaunchingRockets())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBossRocketBarrageAttackActivateParams Params)
	{
		RocketBarrageComp.StartLaunching(Params.Target);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
}