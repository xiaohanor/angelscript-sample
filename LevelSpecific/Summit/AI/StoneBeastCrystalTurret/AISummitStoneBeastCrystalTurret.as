UCLASS(Abstract)
class AAISummitStoneBeastCrystalTurret : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SummitStoneBeastCrystalTurretBehaviourCompoundCapability");

	UPROPERTY(DefaultComponent)
	UDragonSwordCombatResponseComponent SwordResponseComp;

	UPROPERTY(DefaultComponent, Attach=MeshOffsetComponent)
	USceneComponent BasePivot;

	UPROPERTY(DefaultComponent, Attach=BasePivot)
	USceneComponent BarrelPivot;

	UPROPERTY(DefaultComponent, Attach=BarrelPivot)
	UBasicAIProjectileLauncherComponent LauncherComp;

	UPROPERTY(DefaultComponent, Attach=LauncherComp)
	USceneComponent Muzzle;
	
	USummitStoneBeastCrystalTurretSettings Settings;

	UFUNCTION(BlueprintOverride)
	FVector GetFocusLocation() const
	{
		return ActorLocation + FVector::UpVector * 100;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Settings = USummitStoneBeastCrystalTurretSettings::GetSettings(this);
		SwordResponseComp.OnHit.AddUFunction(this, n"OnSwordHit");
		HealthComp.OnDie.AddUFunction(this, n"OnTurretDeath");
	}

	UFUNCTION()
	private void OnSwordHit(UDragonSwordCombatUserComponent CombatComp, FDragonSwordHitData HitData, AHazeActor Instigator)
	{
		HealthComp.TakeDamage(Settings.DefaultDamage, HitData.DamageType, Instigator);
		USummitStoneBeastCrystalTurretEffectHandler::Trigger_OnDamage(this, FSummitStoneBeastCrystalTurretDamageParams(HitData.ImpactPoint));
	}

	UFUNCTION()
	private void OnTurretDeath(AHazeActor ActorBeingKilled)
	{
		USummitStoneBeastCrystalTurretEffectHandler::Trigger_OnDeath(this);
	}
}