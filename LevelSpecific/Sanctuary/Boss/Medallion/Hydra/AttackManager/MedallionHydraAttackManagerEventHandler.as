struct FSanctuaryBossMedallionManagerEventPhaseData
{
	UPROPERTY()
	EMedallionPhase Phase;
	UPROPERTY()
	bool bNaturalProgression = false;
}

struct FSanctuaryBossMedallionManagerEventAnimationData
{
	UPROPERTY()
	ASanctuaryBossMedallionHydra Hydra;
	UPROPERTY()
	EFeatureTagMedallionHydra Tag; 
	UPROPERTY()
	EFeatureSubTagMedallionHydra SubTag;
	UPROPERTY()
	float CustomPlayRate = 1.0;
}

struct FSanctuaryBossMedallionManagerEventAttackData
{
	UPROPERTY()
	ASanctuaryBossMedallionHydra Hydra;
	UPROPERTY()
	EMedallionHydraAttack AttackType;
}

struct FSanctuaryBossMedallionManagerEventPlayerAttackData
{
	UPROPERTY()
	ASanctuaryBossMedallionHydra Hydra;
	UPROPERTY()
	EMedallionHydraAttack AttackType;
	UPROPERTY()
	AHazePlayerCharacter TargetPlayer;
}

struct FSanctuaryBossMedallionManagerEventProjectileData
{
	UPROPERTY()
	ASanctuaryBossMedallionHydra Hydra;
	UPROPERTY()
	AHazeActor Projectile;
	UPROPERTY()
	EMedallionHydraProjectileType ProjectileType;
	UPROPERTY()
	FVector StartLocation;
	UPROPERTY()
	AHazePlayerCharacter MaybeTargetPlayer;
	UPROPERTY()
	FVector MaybeTargetLocation;
	UPROPERTY()
	AHazeActor MaybeActorTarget;
}

struct FSanctuaryBossMedallionManagerEventSplitProjectileData
{
	UPROPERTY()
	AHazeActor Projectile;
	UPROPERTY()
	int SplitCount = 0;
}

struct FSanctuaryBossMedallionManagerHydraData
{
	UPROPERTY()
	ASanctuaryBossMedallionHydra Hydra;
}

struct FSanctuaryBossMedallionManagerPlayerData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FSanctuaryBossMedallionManagerHydraVocalizationData
{
	UPROPERTY()
	ASanctuaryBossMedallionHydra Hydra;

	UPROPERTY()
	UHazeAudioEvent VocalizationEvent;

	UPROPERTY()
	EMedallionHydra HydraType;
}


struct FSanctuaryBossMedallionHydraGhostLaserData
{
	UPROPERTY()
	ASanctuaryBossMedallionHydra Hydra;
	UPROPERTY()
	AMedallionHydraGhostLaser GhostLaser;
	UPROPERTY()
	AHazePlayerCharacter PlayerTarget;
	UPROPERTY()
	float TelegraphDuration = 0.0;
}

UCLASS(Abstract)
class UMedallionHydraAttackManagerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBossPhaseChanged(FSanctuaryBossMedallionManagerEventPhaseData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Phase: " + NewData.Phase);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRequestedAnimationChanged(FSanctuaryBossMedallionManagerEventAnimationData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Anim: " + NewData.Tag);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAttackStarted(FSanctuaryBossMedallionManagerEventAttackData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Attack: " + NewData.AttackType);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShootProjectile(FSanctuaryBossMedallionManagerEventProjectileData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Projectile: " + NewData.ProjectileType);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnProjectileImpact(FSanctuaryBossMedallionManagerEventProjectileData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Projectile: " + NewData.ProjectileType);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSplitProjectileSplit(FSanctuaryBossMedallionManagerEventSplitProjectileData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Projectile: " + NewData.ProjectileType);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnProjectileHitWater(FSanctuaryBossMedallionManagerEventProjectileData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Projectile: " + NewData.ProjectileType);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartRainAttack(FSanctuaryBossMedallionManagerEventPlayerAttackData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Projectile: " + NewData.ProjectileType);
	}	

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRainAttackStartFall(FSanctuaryBossMedallionManagerEventPlayerAttackData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Projectile: " + NewData.ProjectileType);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMoveToSidescrollerSpamAttack(FSanctuaryBossMedallionManagerEventPlayerAttackData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Projectile: " + NewData.ProjectileType);
	}	

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpamAttackStart(FSanctuaryBossMedallionManagerEventPlayerAttackData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Projectile: " + NewData.ProjectileType);
	}	

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpamAttackStop(FSanctuaryBossMedallionManagerEventPlayerAttackData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Projectile: " + NewData.ProjectileType);
	}	

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMeteorAttackStart(FSanctuaryBossMedallionManagerEventPlayerAttackData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Projectile: " + NewData.ProjectileType);
	}	

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMoveToSidescrollerLaser(FSanctuaryBossMedallionHydraEventPlayerAttackData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Projectile: " + NewData.ProjectileType);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraphSidescrollerLaser(FSanctuaryBossMedallionHydraEventPlayerAttackData NewData) 
	{
		// PrintToScreen("Hydra_" + NewData.AttackedHydra.ActorNameOrLabel + " OnTelegraphSidescrollerLaser: " + NewData.PlayerTarget, 10.0);
	}	

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSidescrollerLaserStart(FSanctuaryBossMedallionHydraEventPlayerAttackData NewData) 
	{
		// PrintToScreen("Hydra_" + NewData.AttackedHydra.ActorNameOrLabel + " OnSidescrollerLaserStart: " + NewData.PlayerTarget, 10.0);
	}	

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSidescrollerLaserStop(FSanctuaryBossMedallionHydraEventPlayerAttackData NewData) 
	{
		// PrintToScreen("Hydra_" + NewData.AttackedHydra.ActorNameOrLabel + " OnSidescrollerLaserStop: " + NewData.PlayerTarget, 10.0);
	}	

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSidescrollerLaserExitAnimation(FSanctuaryBossMedallionHydraEventPlayerAttackData NewData) 
	{
		// PrintToScreen("Hydra_" + NewData.AttackedHydra.ActorNameOrLabel + " OnSidescrollerLaserExitAnimation: " + NewData.PlayerTarget, 10.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSidescrollerLaserDeactivate(FSanctuaryBossMedallionHydraEventPlayerAttackData NewData)
	{
		// PrintToScreen("Hydra_" + NewData.AttackedHydra.ActorNameOrLabel + " OnSidescrollerLaserDeactivate: " + NewData.PlayerTarget, 10.0);
	}	

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraphLaser(FSanctuaryBossMedallionHydraGhostLaserData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Projectile: " + NewData.ProjectileType);
	}	

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaserStart(FSanctuaryBossMedallionHydraGhostLaserData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Projectile: " + NewData.ProjectileType);
	}	

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaserImpactWater(FSanctuaryBossMedallionHydraGhostLaserData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Projectile: " + NewData.ProjectileType);
	}	

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaserStop(FSanctuaryBossMedallionHydraGhostLaserData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Projectile: " + NewData.ProjectileType);
	}	

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayersApproachHighFiveScreenMerge() 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Players Highfivin");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayersStartTryHighfive() 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Players Highfivin");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDecapitationMashStart(FSanctuaryBossMedallionManagerHydraData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "OnDecapitationMashStart : " + NewData.AttackedHydra.ActorNameOrLabel);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDecapitation(FSanctuaryBossMedallionManagerHydraData NewData) {}

	// ensure "correct" hydra is dead
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDidSneakyResurrection(FSanctuaryBossMedallionManagerHydraData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "OnDidSneakyResurrection");
	} 

	// ensure "correct" hydra is dead
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDidSneakyDeath(FSanctuaryBossMedallionManagerHydraData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "OnDidSneakyDeath");
	} 
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTriggerVocalization(FSanctuaryBossMedallionManagerHydraVocalizationData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "OnDidSneakyDeath");
	} 
};