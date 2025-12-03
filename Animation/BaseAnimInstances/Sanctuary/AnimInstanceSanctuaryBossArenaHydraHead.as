enum EArenaHydraState
{
	Idle = 0,
	RainAttack,
	WaveAttack,
	ProjectileAttack,

	Submerging,
	Emerging,

	ToAttackSwoopback,
	ToAttackEntry,
	ToAttackApproach,
	ToAttackIdle,
	ToAttackRetract,
	ToAttackBiteLunge,
	ToAttackBiteDown,
	ToAttackBiteRetract,
	ToAttackProjectile,
	ToAttackAnticipateSequence,

	IncomingStrangle,
	Strangle,
	TightenStrangle,
	CoopStrangle,
	CoopTightenStrangle,
	Death,

	FriendStrangle,
	FriendDeath,
	FreeStrangle,
}

enum EArenaHydraPhase
{
	Idle = 0,
	ToAttack,
	Strangle,
}

class UAnimInstanceSanctuaryBossArenaHydraHead : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly)
	FLocomotionFeatureHydraBossArenaAnimData ArenaAnimData;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSkydiveHydraBossAnimData SkydiveAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ASanctuaryBossArenaHydraHead HydraHead;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FHazeRuntimeSpline Spline;

	private UBasicAIHealthComponent HydraHealth;

	EArenaHydraState LastHydraState;
	UPROPERTY()
	EArenaHydraState HydraState;

	UPROPERTY()
	EArenaHydraPhase HydraPhase;

	UPROPERTY()
	bool bProjectileAttack = false;

	UPROPERTY()
	bool bWaveAttack = false;

	UPROPERTY()
	bool bRainAttack = false;

	UPROPERTY()
	bool bSubmerging = false;
	
	UPROPERTY()
	bool bEmerging = false;
	
	UPROPERTY()
	bool bGloryKill = false; // will remove

	UPROPERTY()
	bool bStrangled = false;

	UPROPERTY()
	bool bTightenStrangle = false;

	UPROPERTY()
	bool bDeath = false;

	UPROPERTY()
	float AnnoyedAmount = 0.0;

	UPROPERTY()
	float FightBack = 0.0;

	UPROPERTY()
	float BarProgress = 0.0;

	UPROPERTY()
	FVector TargetLocation;

	UPROPERTY()
	bool bTargetIsFlying = false;

	UPROPERTY()
	FVector MioLocation;

	UPROPERTY()
	FVector ZoeLocation;

	UPROPERTY()
	bool bMioFlying = false;

	UPROPERTY()
	bool bZoeFlying = false;

	UPROPERTY()
	float LookAtAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlatformPhase;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFlightPhase;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTransform HeadTargetTransform;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector HeadTargetPosition;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator HeadTargetRotation;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		HydraHead = Cast<ASanctuaryBossArenaHydraHead>(HazeOwningActor);
		if (HydraHead == nullptr)
			return;

		ArenaAnimData = HydraHead.LocomotionFeature.ArenaAnimData;
		SkydiveAnimData = HydraHead.LocomotionFeature.SkydiveAnimData;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (HydraHead == nullptr)
			return;
		
		if (HydraHead.TargetPlayer != nullptr)
			TargetLocation = HydraHead.TargetPlayer.ActorLocation;

		UpdateState();
		EventHandler();
	
		// Combining states for easier ABP transition rules
		if (HydraState == EArenaHydraState::Idle || 
			HydraState == EArenaHydraState::WaveAttack ||
			HydraState == EArenaHydraState::ProjectileAttack ||
			HydraState == EArenaHydraState::RainAttack)
		{
			HydraPhase = EArenaHydraPhase::Idle;
		}
		else if (HydraState == EArenaHydraState::ToAttackSwoopback ||
				 HydraState == EArenaHydraState::ToAttackEntry ||
				 HydraState == EArenaHydraState::ToAttackApproach ||
				 HydraState == EArenaHydraState::ToAttackIdle ||
				 HydraState == EArenaHydraState::ToAttackRetract ||
				 HydraState == EArenaHydraState::ToAttackBiteLunge ||
				 HydraState == EArenaHydraState::ToAttackBiteDown ||
				 HydraState == EArenaHydraState::ToAttackBiteRetract ||
				 HydraState == EArenaHydraState::ToAttackProjectile ||
				 HydraState == EArenaHydraState::ToAttackAnticipateSequence
				 )
		{
			HydraPhase = EArenaHydraPhase::ToAttack;
		}
		else 
		{
			HydraPhase = EArenaHydraPhase::Strangle;
		}

		if (SanctuaryHydraDevToggles::Drawing::PrintHydraState.IsEnabled())
		{
			DebugPrintState();
			PrintToScreen("Hydra " + HydraHead.GetHydraNumber() + " State " + HydraState);
		}

		HeadTargetTransform = HydraHead.HeadPivot.WorldTransform;
		Spline = HydraHead.RuntimeSpline;
	
		// ---
		// Bools SHOULD be removed now when we use enums but stuff breaks if we remove it >:(
		bProjectileAttack = HydraState == EArenaHydraState::ProjectileAttack;
		bWaveAttack = HydraState == EArenaHydraState::WaveAttack;
		bRainAttack = HydraState == EArenaHydraState::RainAttack;

		bSubmerging = HydraState == EArenaHydraState::Submerging;
		bEmerging = HydraState == EArenaHydraState::Emerging;

		bDeath = HydraState == EArenaHydraState::Death;
		bStrangled = HydraState == EArenaHydraState::Strangle;
		bTightenStrangle = HydraState == EArenaHydraState::TightenStrangle;

		if (HydraHead.HeadID == ESanctuaryBossArenaHydraHead::Center)
			BarProgress = HydraHead.GetBarProgress();

		FightBack = HydraHead.AccFightBack.Value;

		// ---
		if (HydraHealth != nullptr) // todo(Ylva)
			AnnoyedAmount = 1.0 - (HydraHealth.CurrentHealth / HydraHealth.MaxHealth);
		else if (HydraHead.AttachParentActor != nullptr)
			HydraHealth = UBasicAIHealthComponent::Get(HydraHead.AttachParentActor);

		if (HydraState == EArenaHydraState::FriendStrangle || 
			HydraState == EArenaHydraState::FriendDeath || 
			HydraState == EArenaHydraState::ToAttackAnticipateSequence ||
			(HydraPhase == EArenaHydraPhase::Strangle && HydraState != EArenaHydraState::Emerging))
			LookAtAlpha = 0.0;
		else
			LookAtAlpha = 1.0;

		// Print("AnnoyedAmount: " + AnnoyedAmount, 0.f); // Emils Print
		// Print("FightBack: " + FightBack, 0.f); // Emils Print
		// Print("BarProgress: " + BarProgress, 0.f); // Emils Print
	#if EDITOR
	// add more values if you wish :)
		TEMPORAL_LOG(HydraHead, "Animation (SkeletalMesh)").Value("Phase", HydraPhase);
		TEMPORAL_LOG(HydraHead, "Animation (SkeletalMesh)").Value("State", HydraState);
		TEMPORAL_LOG(HydraHead, "Animation (SkeletalMesh)").Value("BarProgress", BarProgress);
	#endif

	}

	void UpdateState()
	{
		// in order of importance
		// -------
		// STRANGLING AND DEATH
		const FSanctuaryBossHeadStates& ReadableState = HydraHead.GetReadableState();
		LastHydraState = HydraState;

		if (ReadableState.bDeath)
			HydraState = EArenaHydraState::Death;
		else if (ReadableState.bFriendDeath)
			HydraState = EArenaHydraState::FriendDeath;
		else if (ReadableState.bMioTightenStrangle && ReadableState.bZoeTightenStrangle)
			HydraState = EArenaHydraState::CoopTightenStrangle;
		else if (ReadableState.bMioTightenStrangle || ReadableState.bZoeTightenStrangle)
			HydraState = EArenaHydraState::TightenStrangle;
		else if (ReadableState.bMioStrangled && ReadableState.bZoeStrangled)
			HydraState = EArenaHydraState::CoopStrangle;
		else if (ReadableState.bMioStrangled || ReadableState.bZoeStrangled)
			HydraState = EArenaHydraState::Strangle;

		// else if (HydraHead.ExtraHeadReactAttack())
		// 	HydraState = EArenaHydraState::FriendStrangle;
		else if (HydraHead.Friend != nullptr && HydraHead.MyPlayerIsAttacking())
			HydraState = EArenaHydraState::FriendStrangle;
		// -------
		// CHANGING SIDES
		else if (ReadableState.bShouldSurface)
			HydraState = EArenaHydraState::Emerging;
		else if (ReadableState.bShouldDive)
			HydraState = EArenaHydraState::Submerging;
		else if (ReadableState.bFreeStrangle)
			HydraState = EArenaHydraState::FreeStrangle;
		// -------
		// Incoming strangle has higher prio than TO ATTACK
		// else if (HydraHead.ExtraHeadReactIncoming())
		// 	HydraState = EArenaHydraState::IncomingStrangle;
		else if (ReadableState.bIncomingStrangle)
			HydraState = EArenaHydraState::IncomingStrangle;
		// -------
		// TO ATTACK
		else if (HydraHead.PlayerIsInAviationSwoopback())
			HydraState = EArenaHydraState::ToAttackSwoopback;
		else if (HydraHead.PlayerIsInAviationEntry())
			HydraState = EArenaHydraState::ToAttackEntry;
		else if (ReadableState.bToAttackProjectile)
			HydraState = EArenaHydraState::ToAttackProjectile;
		else if (ReadableState.bToAttackApproach)
			HydraState = EArenaHydraState::ToAttackApproach;
		else if (ReadableState.bToAttackRetract)
			HydraState = EArenaHydraState::ToAttackRetract;
		else if (ReadableState.bToAttackBiteLunge)
			HydraState = EArenaHydraState::ToAttackBiteLunge;
		else if (ReadableState.bToAttackBiteDown)
			HydraState = EArenaHydraState::ToAttackBiteDown;
		else if (ReadableState.bToAttackBiteRetract)
			HydraState = EArenaHydraState::ToAttackBiteRetract;
		else if (ReadableState.bToAttackSequenceAnticipation)
			HydraState = EArenaHydraState::ToAttackAnticipateSequence;
		else if (ReadableState.bToAttackIdle)
			HydraState = EArenaHydraState::ToAttackIdle;
		// NORMAL STATES
		else if (ReadableState.bShouldLaunchProjectile)
			HydraState = EArenaHydraState::ProjectileAttack;
		else if (ReadableState.bRainAttack)
			HydraState = EArenaHydraState::RainAttack;
		else if (ReadableState.bWaveAttack)
			HydraState = EArenaHydraState::WaveAttack;
		else
			HydraState = EArenaHydraState::Idle;

	}

	private void EventHandler()
	{
		if (LastHydraState == HydraState)
			return;
		switch (HydraState)
		{
			case EArenaHydraState::Idle:
			{
				USanctuaryBossArenaHydraHeadEventHandler::Trigger_Animation_Idle(HydraHead);
				break;
			}
			case EArenaHydraState::RainAttack:
			{
				USanctuaryBossArenaHydraHeadEventHandler::Trigger_Animation_RainAttack(HydraHead);
				break;
			}
			case EArenaHydraState::WaveAttack:
			{
				USanctuaryBossArenaHydraHeadEventHandler::Trigger_Animation_WaveAttack(HydraHead);
				break;
			}
			case EArenaHydraState::ProjectileAttack:
			{
				USanctuaryBossArenaHydraHeadEventHandler::Trigger_Animation_ProjectileAttack(HydraHead);
				break;
			}
			case EArenaHydraState::Submerging:
			{
				USanctuaryBossArenaHydraHeadEventHandler::Trigger_Animation_Submerge(HydraHead);
				break;
			}
			case EArenaHydraState::Emerging:
			{
				USanctuaryBossArenaHydraHeadEventHandler::Trigger_Animation_Emerge(HydraHead);
				break;
			}
			case EArenaHydraState::FriendStrangle:
			{
				USanctuaryBossArenaHydraHeadEventHandler::Trigger_Animation_FriendIsAttacked(HydraHead);
				break;
			}
			case EArenaHydraState::Strangle:
			{
				USanctuaryBossArenaHydraHeadEventHandler::Trigger_Animation_StrangleAttacked(HydraHead);
				break;
			}
			case EArenaHydraState::FreeStrangle:
			{
				USanctuaryBossArenaHydraHeadEventHandler::Trigger_Animation_StrangleFreed(HydraHead);
				break;
			}
			case EArenaHydraState::Death:
			{
				USanctuaryBossArenaHydraHeadEventHandler::Trigger_Animation_Death(HydraHead);
				break;
			}
			default:
			{
				break;
			}
		}
	}

	void DebugPrintState()
	{
		FLinearColor StateColor = FLinearColor::White;
		if (HydraState >= EArenaHydraState::RainAttack && HydraState <= EArenaHydraState::ProjectileAttack)
			StateColor = ColorDebug::Cyan;
		if (HydraState == EArenaHydraState::Submerging || HydraState == EArenaHydraState::Emerging)
			StateColor = ColorDebug::Ultramarine;
		if (HydraState >= EArenaHydraState::ToAttackApproach && HydraState <= EArenaHydraState::ToAttackRetract)
			StateColor = ColorDebug::Carrot;
		if (HydraState >= EArenaHydraState::ToAttackBiteLunge && HydraState <= EArenaHydraState::ToAttackBiteRetract)
			StateColor = ColorDebug::Saffron;
		if (HydraState == EArenaHydraState::ToAttackProjectile)
			StateColor = ColorDebug::Marigold;
		if (HydraState >= EArenaHydraState::IncomingStrangle && HydraState <= EArenaHydraState::CoopTightenStrangle)
			StateColor = ColorDebug::Vermillion;
		if (HydraState >= EArenaHydraState::Death)
			StateColor = ColorDebug::Vermillion;
		if (HydraState >= EArenaHydraState::FreeStrangle)
			StateColor = ColorDebug::Leaf;
		FString StateString = f"{HydraState:n}";	// You're welcome 🍬👄
		Debug::DrawDebugString(HydraHead.HeadPivot.WorldLocation, "" + StateString, StateColor);
		if (FightBack > KINDA_SMALL_NUMBER)
			Debug::DrawDebugString(HydraHead.HeadPivot.WorldLocation, "\n\nFightBack: " + FightBack, StateColor);
		// Debug::DrawDebugCoordinateSystem(HydraHead.HeadPivot.WorldLocation, HydraHead.HeadPivot.WorldRotation, 5000.0, 100.0);
	}
}