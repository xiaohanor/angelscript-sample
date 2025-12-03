class USanctuaryCompanionAttackCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	USanctuaryCompanionJumpComponent CompanionJumpComp;

	float AttackRange = 5000.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionJumpComp = USanctuaryCompanionJumpComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DeactiveDuration < 4.0)
			return false;

		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		if (!Player.IsAnyCapabilityActive(n"WingSuit"))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PrintToScreen("KILL!", 3.0);
		auto HydraHeads = TListedActors<ASanctuaryBossArenaHydraHead>();
		float ClosestDistance = BIG_NUMBER;
		ASanctuaryBossArenaHydraHead ClosestHydraHead;
		for (auto HydraHead : HydraHeads)
		{
			FVector ClosestLocstionOnSpline = HydraHead.RuntimeSpline.GetClosestLocationToLocation(Owner.ActorLocation);
			FVector ToClosestLocstionOnSpline = Owner.ActorLocation - ClosestLocstionOnSpline;
			float Distance = ToClosestLocstionOnSpline.Size();
			if (Distance < AttackRange && Distance < ClosestDistance)
			{
			//	Debug::DrawDebugSphere(ClosestLocstionOnSpline, 2000.0, 12, FLinearColor::Red, 5.0, 1.0);
				ClosestDistance = Distance;
				ClosestHydraHead = HydraHead;
			}
		}
	
		if (ClosestHydraHead == nullptr)
			return;

		auto Hydra = Cast<ASanctuaryBossArenaHydra>(ClosestHydraHead.AttachParentActor);
		Hydra.HealthComp.TakeDamage(0.2, EDamageType::Default, Owner);
		Niagara::SpawnOneShotNiagaraSystemAttached(CompanionJumpComp.AttackEffect, Owner.RootComponent);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};