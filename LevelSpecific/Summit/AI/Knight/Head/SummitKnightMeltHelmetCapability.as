class USummitKnightMeltHelmetCapability : UHazeCapability
{
	// Assuming OnAcidHit events are networked, we can run this locally
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default CapabilityTags.Add(n"MeltHelmet");
	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UAcidResponseComponent AcidResponseComp;
	USummitKnightHelmetComponent Helmet;
	USummitKnightStageComponent StageComp;
	USummitKnightSettings Settings;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Helmet = USummitKnightHelmetComponent::Get(Owner);
		AcidResponseComp = UAcidResponseComponent::Get(Owner);
		StageComp = USummitKnightStageComponent::Get(Owner);
		Settings = USummitKnightSettings::GetSettings(Owner);

		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
	}

	bool IsHelmetFragile()
	{
		if ((StageComp.Phase == ESummitKnightPhase::MobileEndCircling) || 
			(StageComp.Phase == ESummitKnightPhase::MobileEndRun) || 
			(StageComp.Phase == ESummitKnightPhase::MobileAlmostDead))
			return true;
		return false;
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{	
		if (IsHelmetFragile())
		{
			Helmet.TakeDamage(1.0);
			return;	
		}

		if (!Helmet.IsHit(Hit))
			return;
		Helmet.TakeDamage(Settings.MeltHelmetFractionPerHit);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Helmet.Health > 0.9999)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Helmet.IntactAlpha > 0.9999)
			return true; // Helmet is restored
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (!Helmet.bCollision)
			Helmet.RemoveComponentCollisionBlocker(this);
		Helmet.bCollision = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (IsHelmetFragile())
			Helmet.Remove(); // TODO: UXR hack, melt helmet properly

		if (Time::GetGameTimeSince(Helmet.LastDamageTime) > Settings.MeltHelmetRegenerationCooldown)
			Helmet.Regenerate(Settings.MeltHelmetRegenerationRate * DeltaTime);

		Helmet.UpdateMelting(Settings.MeltHelmetMeltingSpeed, Settings.MeltHelmetDissolvingSpeed, Settings.MeltHelmetUnmeltSpeed, Settings.MeltHelmetUndissolvingSpeed, DeltaTime);

		if (Helmet.bCollision)
		{
			if ((Helmet.IntactAlpha < Settings.MeltHelmetIntactCollisionThreshold) ||
				(Helmet.DissolveAlpha > Settings.MeltHelmetDissolvedCollisionThreshold))
			{
				Helmet.bCollision = false;
				Helmet.AddComponentCollisionBlocker(this);
			}
		}
		else if ((Helmet.IntactAlpha > Math::Min(1.0, Settings.MeltHelmetIntactCollisionThreshold * 1.2) - SMALL_NUMBER) &&
				 (Helmet.DissolveAlpha < Settings.MeltHelmetDissolvedCollisionThreshold * 0.1)) 
		{
			Helmet.bCollision = true;
			Helmet.RemoveComponentCollisionBlocker(this);
		}

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugString(Helmet.WorldLocation + FVector(0.0, 0.0, 700.0), "Melt: " + Helmet.DissolveAlpha, Scale = 2.0);
			if (!Helmet.bCollision)
				Debug::DrawDebugSphere(Helmet.WorldLocation, 400.0, 6, FLinearColor::Red, 10.0);
		}
#endif		
	}
};