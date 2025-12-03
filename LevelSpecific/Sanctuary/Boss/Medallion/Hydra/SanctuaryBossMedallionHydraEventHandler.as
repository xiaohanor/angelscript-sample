struct FSanctuaryBossMedallionHydraEventPhaseData
{
	UPROPERTY()
	EMedallionPhase Phase;
}

struct FSanctuaryBossMedallionHydraEventAnimationData
{
	UPROPERTY()
	EFeatureTagMedallionHydra Tag; 
	UPROPERTY()
	EFeatureSubTagMedallionHydra SubTag;
	UPROPERTY()
	float CustomPlayRate = 1.0;
}

struct FSanctuaryBossMedallionHydraEventAttackData
{
	UPROPERTY()
	EMedallionHydraAttack AttackType;
}

struct FSanctuaryBossMedallionHydraEventPlayerAttackData
{
	UPROPERTY()
	ASanctuaryBossMedallionHydra AttackedHydra;
	UPROPERTY()
	EMedallionHydraAttack AttackType;
	UPROPERTY()
	AHazePlayerCharacter PlayerTarget;
}

struct FSanctuaryBossMedallionHydraEventProjectileData
{
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

struct FSanctuaryBossMedallionHydraEventDecapitationStartData
{
	UPROPERTY()
	ASanctuaryBossMedallionHydra AttackedHydra;
}

UCLASS(Abstract)
class USanctuaryBossMedallionHydraEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	ASanctuaryBossMedallionHydra HydraOwner;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HydraOwner = Cast<ASanctuaryBossMedallionHydra>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBossPhaseChanged(FSanctuaryBossMedallionHydraEventPhaseData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Phase: " + NewData.Phase);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRequestedAnimationChanged(FSanctuaryBossMedallionHydraEventAnimationData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Anim: " + NewData.Tag);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAttackStarted(FSanctuaryBossMedallionHydraEventAttackData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Attack: " + NewData.AttackType);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShootProjectile(FSanctuaryBossMedallionHydraEventProjectileData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Projectile: " + NewData.ProjectileType);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayersStartTryHighfive() 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "Players Highfivin");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDecapitationMashStart(FSanctuaryBossMedallionHydraEventDecapitationStartData NewData) 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "OnDecapitationMashStart : " + NewData.AttackedHydra.ActorNameOrLabel);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDecapitation() {}

	// ensure "correct" hydra is dead
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDidSneakyResurrection() 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "OnDidSneakyResurrection");
	} 

	// ensure "correct" hydra is dead
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDidSneakyDeath() 
	{
		// DevPrintStringEvent("Hydra_" + HydraOwner.ActorNameOrLabel, "OnDidSneakyDeath");
	} 
};