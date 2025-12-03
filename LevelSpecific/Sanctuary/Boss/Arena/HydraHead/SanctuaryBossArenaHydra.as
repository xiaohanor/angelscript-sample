event void FArenaBossHeadDiedEvent(int KillCount);
event void FArenaBossDefeatedEvent();
event void FArenaBossProgressToNextEvent();

class ASanctuaryBossArenaHydra : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	USanctuaryBossArenaHydraHealthBarComponent HealthBarComp;
	default HealthBarComp.HealthBarSegments = 6;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(ArenaHydraActionSelectionSheet);

	UPROPERTY(DefaultComponent)
	USanctuaryBossArenaHydraActionsComponent BossComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapaComp;
	default CapaComp.DefaultCapabilities.Add(n"SanctuaryBossArenaHydraDefeatedCapability");

	TArray<ASanctuaryBossArenaHydraHead> HydraHeads;

	UPROPERTY(BlueprintReadWrite)
	FArenaBossHeadDiedEvent OnArenaBossHeadDiedEvent;

	UPROPERTY(BlueprintReadWrite)
	FArenaBossDefeatedEvent OnArenaBossDefeated;

	UPROPERTY(BlueprintReadWrite)
	FArenaBossProgressToNextEvent OnArenaBossProgressToNextEvent;

	bool bRemovedMioHead = false;
	bool bRemovedZoeHead = false;
	int KillCount = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SanctuaryHydraDevToggles::SanctuaryHydraCategory.MakeVisible();
		UBasicAIHealthBarSettings::SetHealthBarVisibility(this, EBasicAIHealthBarVisibility::AlwaysShow, this);
	
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (auto AttachedActor : AttachedActors)
		{
			auto HydraHead = Cast<ASanctuaryBossArenaHydraHead>(AttachedActor);
			if (HydraHead != nullptr)
			{
				HydraHead.ParentBody = this;
				HydraHeads.Add(HydraHead);
				HydraHead.OnHeadDeath.AddUFunction(this, n"OnHeadDeath");
			}
		}
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	private void MedallionChanged(bool bDisabled)
	{
		for (auto HydraHead : HydraHeads)
		{
			if (bDisabled)
				HydraHead.AddActorDisable(this);
			else if (HydraHead.IsActorDisabledBy(this))
				HydraHead.RemoveActorDisable(this);
		}
	}

	UArenaHydraSettings GetSettings() property
	{
		return Cast<UArenaHydraSettings>(
			GetSettings(UArenaHydraSettings)
		);
	}

	UFUNCTION(BlueprintCallable)
	void SetupProgress(int KilledHeads)
	{
		float KilledHeadsFloat = Math::FloorToFloat(KilledHeads);
		float TotalHeads = Math::FloorToFloat(CompanionAviation::HealthBarHeads);
		float Damage = KilledHeadsFloat / TotalHeads;
		HealthComp.SetCurrentHealth(1.0 - Damage);
		HealthBarComp.RefreshHealthValue();
		KillCount = KilledHeads;
		// CheckHydraDeath();
	
		//OnArenaBossHeadDiedEvent.Broadcast(KillCount);

		if (Settings.DeathType != EArenaHydraDeadType::Alive)
		{
			for (int i = 0; i < KilledHeads; ++i)
			{
				for (auto HydraHead : HydraHeads)
				{
					if (HydraHead != nullptr && !HydraHead.LocalHeadState.bDisableAfterDive)
					{
						if (HydraHead.TargetPlayer == nullptr)
							continue;
						if (HydraHead.GetIsIncapacitatedHead())
							continue;
						if (HydraHead.TargetPlayer.IsMio() && (!bRemovedMioHead || !CompanionAviation::bCoopKill))
						{
							bRemovedMioHead = true;
							if (HydraHead.Settings.DeathType == EArenaHydraDeadType::Decapitated)
								HydraHead.SwitchToDecapNeck();
							else if (HydraHead.Settings.DeathType == EArenaHydraDeadType::Disabled)
								HydraHead.AddActorDisable(HydraHead);
							break;
						}
						if (HydraHead.TargetPlayer.IsZoe() && (!bRemovedZoeHead || !CompanionAviation::bCoopKill))
						{
							bRemovedZoeHead = true;
							if (HydraHead.Settings.DeathType == EArenaHydraDeadType::Decapitated)
								HydraHead.SwitchToDecapNeck();
							else if (HydraHead.Settings.DeathType == EArenaHydraDeadType::Disabled)
								HydraHead.AddActorDisable(HydraHead);
							break;
						}
					}
				}
			}
		}
	}

	bool IsDefeated() const
	{
		return KillCount >= CompanionAviation::HeadsToKill;
	}

	UFUNCTION()
	private void OnHeadDeath()
	{
		++KillCount;
		if (!IsDefeated())
		{
			if (Settings.DeathType != EArenaHydraDeadType::Alive)
			{
				for (auto HydraHead : HydraHeads)
				{
					if (HydraHead != nullptr && !HydraHead.LocalHeadState.bDisableAfterDive)
					{
						if (HydraHead.GetIsIncapacitatedHead())
							continue;
						if (HydraHead.TargetPlayer == nullptr)
							continue;
						if (!HydraHead.MyPlayerSuccessAttack())
							continue;
						if (HydraHead.TargetPlayer.IsMio() && (!bRemovedMioHead || !CompanionAviation::bCoopKill))
						{
							DiveDisableHydraHead(HydraHead);
							break;
						}
						if (HydraHead.TargetPlayer.IsZoe() && (!bRemovedZoeHead || !CompanionAviation::bCoopKill))
						{
							DiveDisableHydraHead(HydraHead);
							break;
						}
					}
				}
			}
		}
		OnArenaBossHeadDiedEvent.Broadcast(KillCount);
	}

	private void DiveDisableHydraHead(ASanctuaryBossArenaHydraHead HydraHeadToDisable)
	{
		if (HydraHeadToDisable.TargetPlayer != nullptr && HydraHeadToDisable.TargetPlayer.IsMio())
			bRemovedMioHead = true;
		if (HydraHeadToDisable.TargetPlayer != nullptr && HydraHeadToDisable.TargetPlayer.IsZoe())
			bRemovedZoeHead = true;
		HydraHeadToDisable.LocalHeadState.bShouldDive = true;
		HydraHeadToDisable.LocalHeadState.bDisableAfterDive = true;
	}

	UFUNCTION()
	private void AntiClimaxPhase()
	{
		float NewHydraAmount = 8.0; // Todo(Ylva) Needs to be hooked to some actual heads
		float YawIncrement = 360.0 / NewHydraAmount;

		for (int i = 0; i < HydraHeads.Num(); ++i)
		{
			ASanctuaryBossArenaHydraHead HydraHead = HydraHeads[i];
			HydraHead.RemoveActorDisable(HydraHead);
			FRotator RotationAroundLocation = FRotator::MakeFromEuler(FVector(0.0, 0.0, YawIncrement));
			FVector Offset = RotationAroundLocation.RotateVector(FVector::ForwardVector) * Settings.HydraEmergeRadiusOffset;
			HydraHead.SetActorLocation(ActorLocation + Offset);
			HydraHead.SetActorRotation(FRotator::MakeFromXZ(-Offset.GetSafeNormal(), FVector::UpVector));
			HydraHead.LocalHeadState.bShouldDive = false;
			HydraHead.LocalHeadState.bShouldSurface = true;
			HydraHead.bAntiClimaxPhase = true;
			HydraHead.AccAntiClimaxRise.SnapTo(-0.5);
		}

		Timer::SetTimer(this, n"ProgressToHydraSkydive", Settings.DelayAfterAntiClimaxToSkydive);
	}

	UFUNCTION()
	private void ProgressToHydraSkydive()
	{
		OnArenaBossProgressToNextEvent.Broadcast();
	}

	void KillHead(ESanctuaryBossArenaHydraHead HeadID)
	{
		for (auto Head : HydraHeads)
		{
			bool bAlreadyDying = Head.LocalHeadState.bDeath || Head.GetReadableState().bDeath;
			if (Head.HeadID == HeadID && !bAlreadyDying)
			{
				Head.Die();
				if (HydraHeads.Num() > 0)
				{
					float HeadsToKillFloat = Math::FloorToFloat(CompanionAviation::HeadsToKill);
					HealthComp.TakeDamage(0.5 / HeadsToKillFloat, EDamageType::Default, this);
				}
				break;
			}
		}
	}
};