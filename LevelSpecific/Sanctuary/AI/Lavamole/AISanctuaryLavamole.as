event void FSanctuaryMoleDiedSignature(AAISanctuaryLavamole Mole);

asset LavaMoleBaseSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USanctuaryLavaMoleActionSelectionCapability);
	Capabilities.Add(USanctuaryLavamoleFacePlayerCapability);
	Capabilities.Add(USanctuaryLavamoleShowHealthbarCapability);
	
	Capabilities.Add(USanctuaryLavamoleAutoDamageCapability);
};

asset LavaMoleBittenSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USanctuaryLavamoleBittenPullOutOfHoleCapability);
	Capabilities.Add(USanctuaryLavamoleBittenByOneCapability);
	Capabilities.Add(USanctuaryLavamoleBittenByBothCapability);
};

enum ESanctuaryLavamoleAnimation
{
	None,
	AnticipateShoot,
	Shoot,
	Appear,
	IdleAbove,
	Disappear,
	IdleBelow,
	TakeDamage,
	BodyDying,
}

class AAISanctuaryLavamole : ABasicAICharacter
{
	default CapabilityComp.DefaultSheets.Add(LavaMoleBaseSheet);
	default CapabilityComp.DefaultSheets.Add(LavaMoleBittenSheet);
	// default CapabilityComp.DefaultSheets.Add(LavaMoleActionSelectionSheet);

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileLauncherComponent MortarLauncher;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionComp;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AutoAimComp;

	UPROPERTY(DefaultComponent)
	USanctuaryLavamoleDigComponent DigComponent;

	UPROPERTY(DefaultComponent)
	USanctuaryLavamoleCentipedeBiteResponseComponent Bite1Comp;

	UPROPERTY(DefaultComponent)
	USanctuaryLavamoleCentipedeBiteResponseComponent Bite2Comp;

	UPROPERTY(DefaultComponent)
	USanctuaryLavamoleMultiBoulderComponent ShootComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBar;

	UPROPERTY(Category = "Player Feedback", EditDefaultsOnly)
	UForceFeedbackEffect GrabbedForceFeedbackEffect;

	UPROPERTY(Category = "Player Feedback", EditDefaultsOnly)
	UForceFeedbackEffect PulledForceFeedbackEffect;

	UPROPERTY(Category = "Player Feedback", EditDefaultsOnly)
	UForceFeedbackEffect TearingForceFeedbackEffect;

	UPROPERTY(Category = "Player Feedback", EditDefaultsOnly)
	UForceFeedbackEffect TearedForceFeedbackEffect;

	UPROPERTY(Category = "Player Feedback", EditDefaultsOnly)
	UForceFeedbackEffect WhackForceFeedbackEffect;

	UPROPERTY(Category = "Player Feedback", EditDefaultsOnly)
	UForceFeedbackEffect WhackDeathForceFeedbackEffect;

	UPROPERTY(Category = "VFX", EditDefaultsOnly)
	UNiagaraSystem DeathVFX;

	UPROPERTY(Category = "VFX", EditDefaultsOnly)
	UNiagaraSystem WhackedVFX;

	UPROPERTY(EditDefaultsOnly)
	USkeletalMesh BittenBodySkelMesh;

	UPROPERTY(BlueprintReadOnly)
	ESanctuaryLavamoleAnimation AnimationMode = ESanctuaryLavamoleAnimation::IdleBelow;

	ASanctuaryLavamoleDigPoint OccupiedHole = nullptr;

	USanctuaryLavamoleSettings Settings;

	FSanctuaryMoleDiedSignature OnMoleDied;
	FSanctuaryMoleDiedSignature OnMoleStartedDying;
	FRotator OriginalRotation;

	ESanctuaryLavamoleMortarTargetingStrategy MortarTargetingStrategy = ESanctuaryLavamoleMortarTargetingStrategy::MiddleArea;
	int NumMortarsToShoot = 3;

	bool bIsUnderground = true;
	bool bIsWhacky = false;
	bool bHasBeenPulledOutOfBurrow = false;
	bool bIsAggressive = false;

	int WhackedTimes = 0;
	const int WhackTimesDeath = 3;

	AMoleCombatManager Manager;
	UBasicAIProjectileComponent PrimedMortar;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnMoleDied.AddUFunction(this, n"DedMole");
		Settings = USanctuaryLavamoleSettings::GetSettings(this);
		UBasicAIHealthBarSettings::SetHealthBarOffset(this, FVector(0,0,450), this);
		HealthBar.UpdateHealthBarSettings();
		OriginalRotation = FRotator::ZeroRotator;
		SanctuaryCentipedeDevToggles::Draw::Moles.MakeVisible();
		MortarLauncher.AttachToComponent(Mesh, n"Head");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		if (SanctuaryCentipedeDevToggles::Draw::Moles.IsEnabled())
		{
			Debug::DrawDebugString(ActorLocation, "" + GetSaneName(AnimationMode));
		}
#endif
	}

	private FString GetSaneName(ESanctuaryLavamoleAnimation Enum) const
	{
		FString Unused;
		FString Used;
		FString EnumString = "" + Enum;
		FString Splitter = ":";
		String::Split(EnumString, Splitter, Unused, Used, ESearchCase::IgnoreCase, ESearchDir::FromEnd);
		return Used;
	}

	UFUNCTION()
	private void DedMole(AAISanctuaryLavamole DeadMole)
	{
		if (OccupiedHole != nullptr)
			OccupiedHole.Occupant = nullptr;
		RemoveUnlaunchedMortar();
	}

	void RemoveUnlaunchedMortar()
	{
		if (PrimedMortar != nullptr)
		{
			PrimedMortar.Owner.SetActorHiddenInGame(true);
			PrimedMortar.Expire();
			if (SanctuaryCentipedeDevToggles::Draw::Moles.IsEnabled())
				Debug::DrawDebugString(ActorLocation, "removed a mortar", ColorDebug::Magenta, 4.0);
		}
	}

	bool IsInSafeHole()
	{
		if (OccupiedHole != nullptr)
			return OccupiedHole.bSafeDigPoint;
		return false;
	}

	void DisableAutoTargeting(bool Disable)
	{
		Bite1Comp.bDisabledAutoTargeting = Disable;
		Bite2Comp.bDisabledAutoTargeting = Disable;
	}

	UFUNCTION(CrumbFunction)
	void CrumbKillMole(bool bKilledByTearing)
	{
		if (this.IsActorBeingDestroyed())
			return;
		OccupiedHole.SetHoleCollisionEnabled(false);

		Bite1Comp.OnCentipedeBiteStopped.Broadcast(Bite1Comp.BiterParams);
		Bite2Comp.OnCentipedeBiteStopped.Broadcast(Bite2Comp.BiterParams);

		if (DeathVFX != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(DeathVFX, ActorLocation);

		HealthComp.TakeDamage(1000, EDamageType::Default, this);
		OnMoleDied.Broadcast(this);
		USanctuaryLavamoleEventHandler::Trigger_OnDeath(this);
		this.SetAutoDestroyWhenFinished(true);
		this.SetActorEnableCollision(false);
		this.RootComponent.SetVisibility(false, true);

		if (bKilledByTearing && TearedForceFeedbackEffect != nullptr)
		{
			if (Game::Mio.HasControl())
				Game::Mio.PlayForceFeedback(TearedForceFeedbackEffect, false, false, this);
			if (Game::Zoe.HasControl())
				Game::Zoe.PlayForceFeedback(TearedForceFeedbackEffect, false, false, this);
		}
	}

	UFUNCTION()
	void StartAggressive()
	{
		bIsAggressive = true;
	}
	
	UFUNCTION()
	void StopAggressive()
	{
		bIsAggressive = false;
	}

	UFUNCTION()
	void SwitchHole()
	{
		if (HasControl())
		{
			FSanctuaryLavamoleSwitchHoleData Params;
			Params.PreviousHole = OccupiedHole;
			SanctuaryLavamoleStatics::FindFreeHole(this, Params.NewHole, Params.DigLocation);
			CrumbSwitchHole(Params);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbSwitchHole(FSanctuaryLavamoleSwitchHoleData Params)
	{
		if (Params.PreviousHole != nullptr)
		{
			Params.PreviousHole.Occupant = nullptr;
			OccupiedHole.SetHoleCollisionEnabled(false);
		}

		if (!ensure(Params.NewHole != nullptr, "Didn't find a hole for mole!"))
			return;

		SetActorRotation(OriginalRotation);
		SetActorLocation(Params.DigLocation);
		OccupiedHole = Params.NewHole;
		OccupiedHole.Occupant = this;
		if (!IsActorBeingDestroyed())
			OccupiedHole.SetHoleCollisionEnabled(true);
	}
}

namespace SanctuaryLavamoleTags
{
	const FName DigPointTeam = n"DigPointTeam";
}
