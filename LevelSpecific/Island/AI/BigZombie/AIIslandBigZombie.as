UCLASS(Abstract)
class AAIIslandBigZombie : ABasicAIGroundMovementCharacter
{
	// TODO: Scifi Melee Targetable and Damage Components are added in BP, there should be specific ones for Island.	

	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandBigZombieBehaviourCompoundCapability");

	UPROPERTY(DefaultComponent)
	UIslandZombieDeathComponent DeathComp;

	UPROPERTY(DefaultComponent)
	UScifiCopsGunShootTargetableComponent CopsGunsShootTargetableComp;

	UPROPERTY(DefaultComponent)
	UScifiCopsGunThrowTargetableComponent CopsGunsThrowTargetableComp;

	UPROPERTY(DefaultComponent)
	UIslandNunchuckTargetableComponent NunchuckTargetableComp;

	UPROPERTY(DefaultComponent)
	UScifiCopsGunImpactResponseComponent CopsGunsImpactResponseComp;

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
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);
	default RequestCapabilityComp.PlayerSheets.Add(IslandBigZombieSheet);
}

asset IslandBigZombieSheet of UHazeCapabilitySheet
{
	Components.Add(UIslandBigZombieAttackResponseComponent);
}