struct FIslandProjectileImpactParams
{
	FIslandProjectileImpactParams(FVector Location)
	{
		HitLocation = Location;
	}

	UPROPERTY()
	FVector HitLocation;
}

struct FIslandShieldotronAimingEventData
{
	FIslandShieldotronAimingEventData(UIslandShieldotronLaserAimingComponent InAimingComp)
	{
		AimingComponent = InAimingComp;
	}

	UPROPERTY(BlueprintReadOnly)
	UIslandShieldotronLaserAimingComponent AimingComponent;
}

struct FIslandJetpackImpactDeathParams
{
	FIslandJetpackImpactDeathParams(FVector Location, FVector Normal)
	{
		ImpactLocation = Location;
		ImpactNormal = Normal;
	}

	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	FVector ImpactNormal;
}

struct FIslandShieldotronJumpBoostParams
{
	FIslandShieldotronJumpBoostParams(USceneComponent _JumpBoostJetpack)
	{
		JumpBoostJetpack = _JumpBoostJetpack;
	}

	UPROPERTY()
	USceneComponent JumpBoostJetpack;
}

struct FIslandShieldotronRocketAttackTelegraphParams
{
	FIslandShieldotronRocketAttackTelegraphParams(USceneComponent _LauncherComp)
	{
		LauncherComp = _LauncherComp;
	}

	UPROPERTY()
	USceneComponent LauncherComp;
}

struct FIslandShieldotronOrbAttackTelegraphParams
{
	FIslandShieldotronOrbAttackTelegraphParams(USceneComponent _LauncherComp, float _TelegraphDuration)
	{
		LauncherComp = _LauncherComp;
		TelegraphDuration = _TelegraphDuration;
	}

	UPROPERTY()
	USceneComponent LauncherComp;

	UPROPERTY()
	float TelegraphDuration;
}

struct FIslandShieldotronCloseRangeAttackTelegraphParams
{
	FIslandShieldotronCloseRangeAttackTelegraphParams(USceneComponent _LauncherComp, float _TelegraphDuration)
	{
		LauncherComp = _LauncherComp;
		TelegraphDuration = _TelegraphDuration;
	}

	UPROPERTY()
	USceneComponent LauncherComp;

	UPROPERTY()
	float TelegraphDuration;
}


struct FIslandShieldotronCloseRangeAttackParams
{
	FIslandShieldotronCloseRangeAttackParams(USceneComponent _LauncherComp, FVector _Location, float _Duration)
	{
		LauncherComp = _LauncherComp;
		Location = _Location;
		Duration = _Duration;
	}

	UPROPERTY()
	USceneComponent LauncherComp;

	UPROPERTY()
	FVector Location;

	UPROPERTY()
	float Duration;
}

UCLASS(Abstract)
class UIslandShieldotronEffectHandler : UHazeEffectEventHandler
{
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartDying() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath() {}

	// Deprecated
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnJetpackImpactDeath(FIslandJetpackImpactDeathParams Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDamage(FIslandProjectileImpactParams Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStunned() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnJumpStart(FIslandShieldotronJumpBoostParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnJumpStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnRocketAttackTelegraphStart(FIslandShieldotronRocketAttackTelegraphParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnRocketAttackTelegraphStop() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnOrbAttackTelegraphStart(FIslandShieldotronOrbAttackTelegraphParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnOrbAttackTelegraphStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnCloseRangeAttackTelegraphStart(FIslandShieldotronCloseRangeAttackTelegraphParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnCloseRangeAttackTelegraphStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnCloseRangeAttackLaunch(FIslandShieldotronCloseRangeAttackParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnMeleeAttackStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnMeleeAttackHit() {}
}

