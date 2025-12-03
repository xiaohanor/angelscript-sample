class ADentistBossToolHammer : ADentistBossTool
{
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	USceneComponent HandAttachRoot;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformTemporalLogComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
	default ListedActorComp.bDelistWhileActorDisabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		AddActorDisable(Dentist);
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

	void Reset() override
	{
		Super::Reset();
	}
};