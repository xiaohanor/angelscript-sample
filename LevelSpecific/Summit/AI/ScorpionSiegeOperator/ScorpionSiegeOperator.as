UCLASS(Abstract)
class AScorpionSiegeOperator : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"ScorpionSiegeOperatorBehaviourCompoundCapability");

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;
	UPROPERTY(DefaultComponent)
	UScorpionSiegeOperatorOperationComponent OperationComp;
	UPROPERTY(DefaultComponent, Attach="CharacterMesh0", AttachSocket="RightAttach")
	UBasicAIProjectileLauncherComponent ProjComp;
	UPROPERTY(DefaultComponent)
	UGentlemanCostComponent GentCostComp;
	UPROPERTY(DefaultComponent)
	UGentlemanCostQueueComponent GentCostQueueComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		this.JoinTeam(ScorpionSiegeTeams::OperatorTeam);
	}
	
	// TODO: Once damage responses is implemented, we should not deal damage if we are operating (do take damage when repairing), we die along with the siege weapon
	void DragonDamage()
	{
		if(OperationComp.bOperating && OperationComp.TargetWeapon.HealthComp.IsAlive()) return;
	}
}