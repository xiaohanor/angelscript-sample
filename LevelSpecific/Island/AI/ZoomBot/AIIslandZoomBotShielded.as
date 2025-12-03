UCLASS(Abstract)
class AAIIslandZoomBotShielded : ABasicAIFlyingCharacter
{
	// Do not use pathfinding, just move straight to destination
	default MoveToComp.DefaultSettings = BasicAIFlyingIgnorePathfindingMoveToSettings;

	default CapsuleComponent.RelativeLocation = FVector::ZeroVector;
	default CapsuleComponent.CapsuleHalfHeight = 40.0;
	default CapsuleComponent.CapsuleRadius = 40.0;

	default CapabilityComp.DefaultCapabilities.Add(n"IslandZoomBotBehaviourCompoundCapability");

	UPROPERTY(DefaultComponent)
	UScifiCopsGunShootTargetableComponent CopsGunsShootTargetableComp;

	UPROPERTY(DefaultComponent)
	UScifiCopsGunThrowTargetableComponent CopsGunsThrowTargetableComp;

	UPROPERTY(DefaultComponent)
	UScifiCopsGunDamageableComponent CopsGunDamageComp;

	UPROPERTY(DefaultComponent, Attach = "CollisionCylinder")
	UIslandNunchuckTargetableComponent NunchuckTargetableComp;
	default NunchuckTargetableComp.TargetableRange.Max = 2000;

	UPROPERTY(DefaultComponent, Attach = "CollisionCylinder")
	UIslandNunchuckDamageableComponent NunchuckDamageComp;
	default NunchuckDamageComp.DamageSettings = ZoomBotNunchuckDamageSettings;

	UPROPERTY(DefaultComponent)
	UScifiShieldBusterFieldTargetableComponent ShieldBusterFieldTargetableComp;

	UPROPERTY(DefaultComponent)
	UScifiShieldBusterImpactResponseComponent ShieldBusterImpactComp;


	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightAttach")
	UBasicAIMeleeWeaponComponent Weapon;


	UPROPERTY(DefaultComponent)
	UCombatHitStopComponent HitStopComp;

	UPROPERTY(DefaultComponent)
	UScifiShieldBusterField ShieldComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		BlockCapabilities(n"TakeDamage", this);
		ShieldComp.OnBreak.AddUFunction(this, n"OnShieldBreak");
		ShieldComp.OnRecover.AddUFunction(this, n"OnShieldRecover");
	}

	UFUNCTION()
	private void OnShieldRecover()
	{
		BlockCapabilities(n"TakeDamage", this);
	}

	UFUNCTION()
	private void OnShieldBreak()
	{
		if(IsCapabilityTagBlocked(n"TakeDamage"))
			UnblockCapabilities(n"TakeDamage", this);
	}

	UFUNCTION()
	private void OnReset()
	{
		ShieldComp.Reset();
	}
}