UCLASS(Abstract)
class AAIIslandNecromancer : ABasicAIGroundMovementCharacter
{
	// TODO: Scifi Melee Targetable and Damage Components are added in BP, there should be specific ones for Island.	

	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandNecromancerBehaviourCompoundCapability");

	UPROPERTY(DefaultComponent)
	UIslandZombieDeathComponent DeathComp;

	UPROPERTY(DefaultComponent)
	UScifiCopsGunDamageableComponent DamageComp;

	UPROPERTY(DefaultComponent)
	UScifiCopsGunShootTargetableComponent CopsGunsShootTargetableComp;

	UPROPERTY(DefaultComponent)
	UScifiCopsGunThrowTargetableComponent CopsGunsThrowTargetableComp;

	UPROPERTY(DefaultComponent)
	UIslandNunchuckTargetableComponent NunchuckTargetableComp;

	UPROPERTY(DefaultComponent)
	UIslandPushKnockSelfImpactResponseComponent KnockSelfImpactComp;

	UPROPERTY(DefaultComponent)
	UIslandPushKnockTargetImpactResponseComponent KnockTargetImpactComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightAttach")
	UBasicAIMeleeWeaponComponent Weapon;


	UPROPERTY(DefaultComponent)
	UCombatHitStopComponent HitStopComp;

	UPROPERTY(DefaultComponent)
	UIslandPushKnockComponent PushKnockComp;

	UPROPERTY(DefaultComponent)
	UIslandBigZombieAttackResponseComponent BigZombieAttackResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		this.JoinTeam(IslandNecromancerTags::IslandNecromancerTeam);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		this.LeaveTeam(IslandNecromancerTags::IslandNecromancerTeam);
	}
}

namespace IslandNecromancerTags
{
	const FName IslandNecromancerTeam = n"IslandNecromancerTeam";
	const FName IslandNecromancerReviveTargetTeam = n"IslandNecromancerReviveTargetTeam";
}