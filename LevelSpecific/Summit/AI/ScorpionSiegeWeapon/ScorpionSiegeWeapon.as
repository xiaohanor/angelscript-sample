UCLASS(Abstract)
class AScorpionSiegeWeapon : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"ScorpionSiegeWeaponBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;
	UPROPERTY(DefaultComponent, Attach="CharacterMesh0")
	UBasicAIProjectileLauncherComponent ProjComp;
	UPROPERTY(DefaultComponent)
	USphereComponent OperatorSlot1;
	UPROPERTY(DefaultComponent)
	USphereComponent OperatorSlot2;
	UPROPERTY(DefaultComponent)
	UScorpionSiegeWeaponManagerComponent Manager;
	UPROPERTY(DefaultComponent)
	UScorpionSiegeWeaponRepairComponent RepairComp;
	UPROPERTY(DefaultComponent, Attach="CharacterMesh0")
	UHazeCharacterSkeletalMeshComponent BrokenMesh;
	UPROPERTY(DefaultComponent)
	UGentlemanCostComponent GentCostComp;
	UPROPERTY(DefaultComponent)
	UGentlemanCostQueueComponent GentCostQueueComp;

	UPROPERTY(DefaultComponent)
	UBasicAIPerceptionComponent PerceptionComp;
	default PerceptionComp.Sight = USummitTeenDragonAIPerceptionSight();

	UScorpionSiegeWeaponSettings ScorpionSettings;
	TArray<USphereComponent> OperatorSlots;

	int WantedOperators = 2;

	bool GetbOperational() property
	{
		return Manager.ActiveOperators >= WantedOperators && HealthComp.IsAlive();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ScorpionSettings = UScorpionSiegeWeaponSettings::GetSettings(this);
		UBasicAIMovementSettings::GetSettings(this).TurnDuration = ScorpionSettings.TurnDuration;		
		this.JoinTeam(ScorpionSiegeTeams::WeaponTeam);
		
		Mesh.SetVisibility(true);
		BrokenMesh.SetVisibility(false);

		UMovementGravitySettings::SetGravityAmount(this, 0.0, this, EHazeSettingsPriority::Gameplay);

		OperatorSlots.Add(OperatorSlot1);
		OperatorSlots.Add(OperatorSlot2);
	}

	void Revive()
	{		
		HealthComp.Reset();
		RepairComp.Reset();
		Mesh.SetVisibility(true);
		BrokenMesh.SetVisibility(false);
	}
}