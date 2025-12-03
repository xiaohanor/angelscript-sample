class ADentistBossToolChair : ADentistBossTool
{
	UPROPERTY(DefaultComponent)
	USceneComponent PlayerAttachLocation;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformTemporalLogComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"DentistBossToolChairWiggleCapability");
	default CapabilityComp.bCanBeDisabled = false;

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