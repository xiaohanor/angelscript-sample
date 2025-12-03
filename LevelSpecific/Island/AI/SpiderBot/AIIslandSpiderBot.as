UCLASS(Abstract)
class AAIIslandSpiderBot : ABasicAIWallclimbingCharacter
{
	default CapsuleComponent.CapsuleHalfHeight = 40.0;
	default CapsuleComponent.CapsuleRadius = 40.0;

	default CapabilityComp.DefaultCapabilities.Add(n"IslandSpiderBotBehaviourCompoundCapability");

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

	UPROPERTY(DefaultComponent)
	UScifiShieldBusterFieldTargetableComponent ShieldBusterFieldTargetableComp;

	UPROPERTY(DefaultComponent)
	UScifiShieldBusterImpactResponseComponent ShieldBusterImpactComp;

	UPROPERTY(DefaultComponent)
	UCombatHitStopComponent HitStopComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		RespawnComp.OnRespawn.AddUFunction(this, n"OnSpawn");
	}

	UFUNCTION()
	private void OnSpawn()
	{
		this.OverrideGravityDirection(-ActorUpVector, this, EInstigatePriority::Low);
	}
}