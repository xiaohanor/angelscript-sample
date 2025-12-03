class AAISanctuaryGrimbeast : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryGrimbeastBehaviourCompoundCapability");
	default CapabilityComp.DefaultSheets.Add(GrimbeastActionSelectionSheet);

	UPROPERTY(DefaultComponent, Attach = "Root")
	UHazeSphereComponent HazeSphereComponent;

	UPROPERTY(DefaultComponent)
	USanctuaryGrimbeastMultiBoulderLauncherComponent MultiBoulderLauncher;

	UPROPERTY(DefaultComponent)
	UCentipedeProjectileResponseComponent CentipedeProjectileResponseComp;

	UPROPERTY(DefaultComponent)
	UCentipedeProjectileTargetableComponent CentipedeProjectileTargetableComponent;

	USanctuaryGrimbeastSettings Settings;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBar;

	UPROPERTY(DefaultComponent)
	USanctuaryLavaApplierComponent LavaComp;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance NormalMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance FrozenMaterial;

	UFUNCTION(BlueprintOverride)
	FVector GetFocusLocation() const
	{
		return ActorLocation + ActorUpVector * 500;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		CentipedeProjectileResponseComp.OnImpact.AddUFunction(this, n"OnHit");
		Settings = USanctuaryGrimbeastSettings::GetSettings(this);
	}

	UFUNCTION()
	private void OnHit(FVector ImpactDirection, float Force)
	{
		HealthComp.TakeDamage(Settings.CentipedeProjectileDamage, EDamageType::Default, this);
		BP_OnFreezeHit();
		USanctuaryGrimbeastEventHandler::Trigger_OnDeath(this);
	}

	UFUNCTION(BlueprintEvent)
	protected void BP_OnFreezeHit()
	{
	}
}