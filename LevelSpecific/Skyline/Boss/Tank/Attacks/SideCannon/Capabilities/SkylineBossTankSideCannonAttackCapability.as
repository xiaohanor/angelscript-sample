struct FSkylineBossTankSideCannonAttackActivateParams
{
	AHazeActor AttackTarget;
};

class USkylineBossTankSideCannonAttackCapability : USkylineBossTankChildCapability
{
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankAttack);

	TArray<USkylineBossTankSideCannonComponent> SideCannonComponents;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		BossTank.GetComponentsByClass(SideCannonComponents);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBossTankSideCannonAttackActivateParams& Params) const
	{
		if (!BossTank.HasAttackTarget())
			return false;

		if (DeactiveDuration < 3.0)
			return false;

		Params.AttackTarget = BossTank.GetAttackTarget();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBossTankSideCannonAttackActivateParams Params)
	{
		for (auto SideCannonComponent : SideCannonComponents)
		{
			auto Target = Params.AttackTarget;
			FVector TargetLocation = Target.ActorLocation + Target.ActorVelocity.SafeNormal * Math::Min(Target.ActorVelocity.Size(), 3000.0);

			SideCannonComponent.Fire(TargetLocation);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}