event void DentistDrillEvent(AHazePlayerCharacter Player);

class ADentistBossToolDrill : ADentistBossTool
{
	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent DrillRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent DrillMesh;

	UPROPERTY(DefaultComponent, Attach = DrillRoot)
	UStaticMeshComponent DrillTipMesh;

	UPROPERTY(DefaultComponent, Attach = DrillTipMesh)
	USceneComponent DrillEffectAttachRoot;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolDrillAttackCapability);

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.InitialStoppedPlayerCapabilities.Add(n"DentistBossToolDrillTiltPlayerCameraCapability");
	default RequestComp.InitialStoppedPlayerCapabilities.Add(n"DentistBossToolDrillShakePlayerCapability");
	

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformTemporalLogComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
	default ListedActorComp.bDelistWhileActorDisabled = false;

	DentistDrillEvent OnHitPlayer;
	DentistDrillEvent OnStopped;

	UDentistBossSettings Settings;

	AHazePlayerCharacter TargetedPlayer;

	bool bIsDirected = false;
	bool bSpinDrill = false;
	float DrillAlpha = 0.0;

	float CurrentDrillSpeed = 0.0;

	const float DrillAcceleration = 2000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		Settings = UDentistBossSettings::GetSettings(Dentist);
		AddActorDisable(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float TargetDrillSpeed;
		if(bSpinDrill)
			TargetDrillSpeed = Settings.DrillSpeed;
		else	
			TargetDrillSpeed = 0.0;

		CurrentDrillSpeed = Math::FInterpConstantTo(CurrentDrillSpeed, TargetDrillSpeed, DeltaSeconds, DrillAcceleration);
		
		if(!Math::IsNearlyZero(CurrentDrillSpeed))
			DrillRoot.AddRelativeRotation(FRotator(0.0, CurrentDrillSpeed * DeltaSeconds, 0));
	}

	void Activate() override
	{
		Super::Activate();
		
		RemoveActorDisable(Dentist);
	}

	void Deactivate() override
	{
		Super::Deactivate();
		
		AddActorDisable(Dentist);
	}
};