enum EStoneBossPeakPhase
{
	Phase1,
	Phase2,
	Phase3,
	Vulnerable
}

class AStoneBossPeak : AHazeActor
{
	UPROPERTY()
	EStoneBossPeakPhase State;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeSkeletalMeshComponentBase SkelMesh;
	default SkelMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"StoneBossTargetingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"StoneBossPeakProximityAttackCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"StoneBossPeakProjectileAttackCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"StoneBossPeakCrystalBreathAttackCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"StoneBossPeakActivateShieldAmplifierCapability");

	UPROPERTY(EditAnywhere)
	ASplineActor PlayerFollowSpline;

	UPROPERTY()
	TSubclassOf<AStoneBossProximitySpell> ProximitySpellSpawnerClass;

	TArray<AStoneBossPeakShieldAmplifier> ShieldAmplifierProtectors;

	UHazeSplineComponent SplineComp;

	FStonePeakShieldAmplifierData ShieldAmplifierData;
	FStonePeakProjectileSpiralData ProjectileSpiralData;
	FStonePeakCrystalBreathAttackData CrystalBreathData;
	FStonePeakProximityStrikeAttackData ProxmityStrikeAttackData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ShieldAmplifierProtectors = TListedActors<AStoneBossPeakShieldAmplifier>().GetArray();
		
		FStonePeakShieldAmplifierData NewShieldData;
		NewShieldData.bShieldActive = true;
		NewShieldData.ShieldCount = 3;
		SetShield(ShieldAmplifierData);
	}

	void SetShield(FStonePeakShieldAmplifierData Data)
	{
		ShieldAmplifierData = Data;
	}

	void SetProjectileSpiral(FStonePeakProjectileSpiralData Data)
	{
		ProjectileSpiralData = Data;
	}

	void SetCrystalBreath(FStonePeakCrystalBreathAttackData Data)
	{
		CrystalBreathData = Data;
	}

	void SetPrxomityStrike(FStonePeakProximityStrikeAttackData Data)
	{
		ProxmityStrikeAttackData = Data;
	}

	UFUNCTION(CrumbFunction)
	void CrumbActivateVulnerableState()
	{
		State = EStoneBossPeakPhase::Vulnerable;
	}

	void SpawnProximitySpell(FVector Location)
	{
		AStoneBossProximitySpell Prxomity = SpawnActor(ProximitySpellSpawnerClass, Location, bDeferredSpawn = true);
		Prxomity.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
		FinishSpawningActor(Prxomity);	
	}
};