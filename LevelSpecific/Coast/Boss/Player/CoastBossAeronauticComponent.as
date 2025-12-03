UCLASS(Abstract)
class UCoastBossAeronauticComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence RideDroneAnimation;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence ZoeRideDroneAnimation;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ACoastBossPlayerBullet> MioBulletClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ACoastBossPlayerBullet> ZoeBulletClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ACoastBossPlayerBullet> MioHomingBulletClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ACoastBossPlayerBullet> ZoeHomingBulletClass;
	TArray<ACoastBossPlayerBullet> ActiveBullets;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ACoastBossPlayerLaser> MioLaserClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ACoastBossPlayerLaser> ZoeLaserClass;
	ACoastBossPlayerLaser Laser;

	UPROPERTY(EditDefaultsOnly)
	float PlayerCollisionRadius = 90.0;
	float InvulnerablePlayerCollisionRadius = 170.0;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect FFShoot;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect FFHoming;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect FFLaser;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect FFDash;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect FFPickup;

	float DamageMultiplier = 1.0;

	ACoastBossPlayerDrone AttachedToShip;
	bool bAttached = false;
	float Upwards;
	float Forwards;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem BulletImpactVFX;
	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem BulletImpactWeakpointVFX;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem DamagedVFX;
	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem GotImpactDamagedVFX;
	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect IsDamagedFF;
	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect GotDamagedFF;

	UPROPERTY(EditDefaultsOnly)
	FPlayerDeathDamageParams DamageParams;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	UDeathRespawnEffectSettings RespawnEffectSettings;

	float InvincibleFramesCooldown = 0.0;

	FHazeAcceleratedFloat AccDashAlpha;

	private UHazeActionQueueComponent TutorialQueue;
	private UPlayerHealthComponent PlayerHealthComp;
	private AHazePlayerCharacter Player;
	bool bHasShield = true;
	float LastPowerUpTimestamp = 0.0;
	ECoastBossPlayerPowerUpType LastPowerUpType;
	bool bShouldPlayerEnter = false;
	bool bCameraShouldBlendInFromEnter = false;
	bool bPlayerInvulnerable = false;
	float PlayerEnterDuration = 0.0;
	AHazePlayerCharacter RightMostPlayer;

	float InvulnerableImpactTimestamp = 0.0;
	bool bLaserActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TutorialQueue = UHazeActionQueueComponent::Create(Owner, n"CoastBossTutorialQueue");
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerHealthComp = UPlayerHealthComponent::Get(Player);
	}

	void TryDamagePlayer(float Amount, ECoastBossAeuronauticPlayerReceiveDamageType DamageType)
	{
		if (!HasControl())
			return;
		if (!PlayerHealthComp.CanTakeDamage())
			return;
		if (bPlayerInvulnerable)
		{
			float TimeSinceLast = Time::GameTimeSeconds - InvulnerableImpactTimestamp;
			if (TimeSinceLast > 0.1)
			{
				InvulnerableImpactTimestamp = Time::GameTimeSeconds;
				CrumbInvulnerableImpact();
			}
			return;
		}

		CrumbDamage(Amount, DamageType);
	}

	TSubclassOf<ACoastBossPlayerBullet> GetPlayerBulletClass() const property
	{
		if(Player.IsMio())
			return MioBulletClass;

		return ZoeBulletClass;
	}

	TSubclassOf<ACoastBossPlayerBullet> GetPlayerHomingBulletClass() const property
	{
		if(Player.IsMio())
			return MioHomingBulletClass;

		return ZoeHomingBulletClass;
	}

	TSubclassOf<ACoastBossPlayerLaser> GetPlayerLaserClass() const property
	{
		if(Player.IsMio())
			return MioLaserClass;

		return ZoeLaserClass;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbInvulnerableImpact()
	{
		UCoastBossAeuronauticPlayerEventHandler::Trigger_GotImpactDuringInvulnerable(Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDamage(float Amount, ECoastBossAeuronauticPlayerReceiveDamageType DamageType)
	{
		FCoastBossAeuronauticPlayerReceiveDamageData Params;
		Params.DamageType = DamageType;
		UCoastBossAeuronauticPlayerEventHandler::Trigger_GotImpacted(Player, Params);
		if (bHasShield)
		{
			Player.DamagePlayerHealth(0.01, DamageParams, DamageEffect, DeathEffect);
			InvincibleFramesCooldown = CoastBossConstants::Player::InvincibleFramesDuration;
			bHasShield = false;
		}
		else
		{
			Player.KillPlayer(DamageParams, DeathEffect);
			bHasShield = true;
		}
		if (GotDamagedFF != nullptr)
			Player.PlayForceFeedback(GotDamagedFF, false, false, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AccDashAlpha.AccelerateTo(0.0, CoastBossConstants::Player::DashDuration, DeltaSeconds);
		// if (AccDashAlpha.Value > KINDA_SMALL_NUMBER)
		// 	Debug::DrawDebugString(Owner.ActorLocation, "DASHING");
	}

	void ShowTutorial()
	{
		if(!HasControl())
			return;

		TutorialQueue.Capability(UCoastBossPlayerTutorialActionShootCapability);
		TutorialQueue.Idle(1.0);
		TutorialQueue.Capability(UCoastBossPlayerTutorialActionDashCapability);
	}
}

namespace CoastBossPlayerStatics
{
	UFUNCTION()
	void CoastBossSetShouldPlayerSmoothlyEnter(AHazePlayerCharacter Player, float PlayerEnterDuration = 5.0)
	{
		auto AeronauticComp = UCoastBossAeronauticComponent::Get(Player);
		AeronauticComp.bShouldPlayerEnter = true;
		AeronauticComp.PlayerEnterDuration = PlayerEnterDuration;
	}
}
class UCoastBossPlayerTutorialActionShootCapability : UHazeActionQueuePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FTutorialPrompt ShootTutorial;
	default ShootTutorial.Action = ActionNames::WeaponFire;
	default ShootTutorial.Text = NSLOCTEXT("CoastBoss", "ShootTutorial", "Shoot");
	default ShootTutorial.DisplayType = ETutorialPromptDisplay::ActionHold;

	UCoastBossAeronauticComponent AeronauticComp;
	TOptional<float> TimeOfStartShooting;

	const float MaxDuration = 4.0;
	const float LingerDuration = 0.5;

	bool bTutorialShown = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AeronauticComp = UCoastBossAeronauticComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// if(ActiveDuration > MaxDuration)
		// 	return true;


		if(TimeOfStartShooting.IsSet() && Time::GetGameTimeSince(TimeOfStartShooting.Value) > LingerDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ShowTutorial();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HideTutorial();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!TimeOfStartShooting.IsSet() && IsActioning(ActionNames::WeaponFire) && !Player.IsPlayerDead())
			TimeOfStartShooting.Set(Time::GetGameTimeSeconds());

		if(Player.IsPlayerDead())
		{
			HideTutorial();
		}
		else
		{
			ShowTutorial();
		}
	}

	void ShowTutorial()
	{
		if(bTutorialShown)
			return;

		bTutorialShown = true;
		Player.ShowTutorialPromptWorldSpace(ShootTutorial, this, AeronauticComp.AttachedToShip.SkeletalMesh, FVector(0.0, 0.0, -200.0), -20.0);
	}

	void HideTutorial()
	{
		if(!bTutorialShown)
			return;

		bTutorialShown = false;
		Player.RemoveTutorialPromptByInstigator(this);		
	}
}

class UCoastBossPlayerTutorialActionDashCapability : UHazeActionQueuePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FTutorialPrompt DashTutorial;
	default DashTutorial.Action = ActionNames::MovementDash;
	default DashTutorial.Text = NSLOCTEXT("CoastBoss", "DashTutorial", "Dash");

	UCoastBossAeronauticComponent AeronauticComp;
	TOptional<float> TimeOfDash;

	const float MaxDuration = 4.0;
	const float LingerDuration = 0.2;

	bool bTutorialShown = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AeronauticComp = UCoastBossAeronauticComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// if(ActiveDuration > MaxDuration)
		// 	return true;

		if(TimeOfDash.IsSet() && Time::GetGameTimeSince(TimeOfDash.Value) > LingerDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ShowTutorial();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HideTutorial();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

		if(!TimeOfDash.IsSet() && WasActionStarted(ActionNames::MovementDash) && !Player.IsPlayerDead())
			TimeOfDash.Set(Time::GetGameTimeSeconds());

		if(Player.IsPlayerDead())
		{
			HideTutorial();
		}
		else
		{
			ShowTutorial();
		}
	}

	void ShowTutorial()
	{
		if(bTutorialShown)
			return;

		bTutorialShown = true;
			Player.ShowTutorialPromptWorldSpace(DashTutorial, this, AeronauticComp.AttachedToShip.SkeletalMesh, FVector(0.0, 0.0, -200.0), -20.0);
	}

	void HideTutorial()
	{
		if(!bTutorialShown)
			return;
		
		bTutorialShown = false;
		Player.RemoveTutorialPromptByInstigator(this);		
	}
}