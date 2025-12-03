UCLASS(Abstract)
class UEnforcerEffectHandler : UHazeEffectEventHandler
{
	// The owner is about to start launching projectiles (Enforcer.OnTelegraphShooting)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraphShooting(FEnforcerEffectOnTelegraphData Data) {}

	// The owner fired a projectile, triggered for each (Enforcer.OnShotFired)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShotFired() {}

	// The owner fired a projectile or burst of projectiles (Enforcer.OnPostFire)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPostFire() {}

	// The owner starts reloading (Enforcer.OnReload)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReload(FEnforcerEffectOnReloadData Params) {}

	// The owner finished reloading (Enforcer.OnReloadComplete)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReloadComplete() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraphThrowGrenade() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWieldGrenade(FEnforcerEffectOnThrowGrenadeData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrowGrenade(FEnforcerEffectOnThrowGrenadeData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPostGrenadeThrown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAreaAttackImpact() {}

	// The owner took damage (Enforcer.OnTakeDamage)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTakeDamage() {}

	// The owner died (Enforcer.OnDeath)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath(FEnforcerEffectOnDeathData Data) {}

	// The owner unspawned (Enforcer.OnUnspawn)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnUnspawn() {}

	// The owner respawned (Enforcer.OnRespawn)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnRespawn() {}

	// Deprecated - not in use
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnBreakArmor() {}

	// Deprecated - not in use
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnForceFieldBreak() {}

	// Deprecated - not in use
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnForceFieldRestore() {}

	// The owner was grabbed by gravity whip (Enforcer.OnGravityWhipGrabbed)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGravityWhipGrabbed() {}

	// The owner was thrown by gravity whip (Enforcer.OnGravityWhipThrown)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGravityWhipThrown() {}

	// The owner was hit by gravity blade (Enforcer.OnBladeHit)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnBladeHit(FEnforcerEffectOnBladeHitData Data) {}

	// The owner resisted gravity blade (Enforcer.OnBladeResist)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnBladeResist(FEnforcerEffectOnBladeResistData Data) {}

	// Jetpack only, the owner was slung into floor or wall (Enforcer.OnGravityWhipThrowImpact)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGravityWhipThrowImpact(FEnforcerEffectOnGravityWhipThrowImpactData Data) {}

	// Owner was hit by a gravity whip thrown enemy
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGravityWhipStumble() {}

	// The owner advances towards target (Enforcer.OnAdvance)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnAdvance() {}

	// The owner finds a target (Enforcer.OnTargetSighted)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTargetSighted() {}

	// The owner lost a target (Enforcer.OnTargetLost)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTargetLost() {}

	// We just started a glory kill anim synced with blade player
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGloryDeathStart() {}

	// We've activated ragdoll
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnRagdoll() {}

	// Effect event handler for AI VO response in Sound def
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGotYourBackResponse(){}

	// Effect event handler for AI VO response in Sound def
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAffirmativeResponse(){}

	// Effect event handler for AI VO response in Sound def
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAdvanceResponse(){}

	// Effect event handler for AI VO response in Sound def
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPanicResponse(){}

	// Effect event handler for AI VO response in Sound def
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPanicBackupRequestResponse(){}

	// Effect event handler for AI VO response in Sound def
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeathFriendlyResponse(){}

	// Effect event handler for AI VO response in Sound def
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeathFriendlyBackupRequestResponse(){}
	
	// Effect event handler for AI VO response in Sound def, leave as example if event handlers require to send parameters
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTestResponse(FTestVOSomethingParams Params){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChargeMeleeApproachStart(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChargeMeleeApproachStop(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChargeMeleeAttackStart(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChargeMeleeAttackStop(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChargeMeleeAttackImpact(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChargeMeleeAttackHadHit(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChargeMeleeAttackHadMiss(){}
}

struct FTestVOSomethingParams
{
	UPROPERTY()
	float TestFloat;
}

struct FEnforcerEffectOnTelegraphData
{

	UPROPERTY()
	float TelegraphDuration = 0.0;

	FEnforcerEffectOnTelegraphData(float Duration)
	{
		TelegraphDuration = Duration;	
	}
}

struct FEnforcerEffectOnThrowGrenadeData
{
	UPROPERTY()
	AEnforcerGrenade Grenade;

	FEnforcerEffectOnThrowGrenadeData(AActor GrenadeActor)
	{
		Grenade = Cast<AEnforcerGrenade>(GrenadeActor);	
	}
}

struct FEnforcerEffectOnReloadData
{
	UPROPERTY()
	UBasicAIProjectileLauncherComponent Weapon;

	UPROPERTY()
	float ReloadDuration = 0.0;

	FEnforcerEffectOnReloadData(UBasicAIProjectileLauncherComponent Launcher, float Duration)
	{
		Weapon = Launcher;
		ReloadDuration = Duration;	
	}
}

enum EEnforcerDeathType
{
	Default, 
	GloryDeath
}

struct FEnforcerEffectOnDeathData
{
	UPROPERTY(BlueprintReadOnly)
	EEnforcerDeathType DeathType = EEnforcerDeathType::Default;

	UPROPERTY(BlueprintReadOnly)
	float DeathDuration;

	UPROPERTY(BlueprintReadOnly)
	TArray<FName> DismemberedBones;
}

struct FEnforcerEffectOnShieldDeflectData
{
	UPROPERTY(BlueprintReadOnly)
	FVector ImpactWorldLocation;
}

struct FEnforcerEffectOnGravityWhipThrowImpactData
{
	UPROPERTY(BlueprintReadOnly)
	FVector ImpactLocation;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactNormal;
}

struct FEnforcerEffectOnBladeHitData
{
	UPROPERTY(BlueprintReadOnly)
	FVector BloodSpurtWorldDirection;

	UPROPERTY(BlueprintReadOnly)
	FVector BloodSpurtLocalDirection;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactWorldLocation;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactLocalLocation;
}

struct FEnforcerEffectOnBladeResistData
{
	UPROPERTY(BlueprintReadOnly)
	FVector ImpactWorldLocation;
}