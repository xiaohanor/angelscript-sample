class ADentistBossToolScraper : ADentistBossTool
{
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolScraperRestrainPlayerCapability);

	UPROPERTY(DefaultComponent)
	USceneComponent HandAttachRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent TipRoot;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
	default ListedActorComp.bDelistWhileActorDisabled = false;

	TOptional<AHazePlayerCharacter> RestrainedPlayer;

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
		
		RestrainedPlayer.Reset();
	}
};