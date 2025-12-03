class ADentistBossTool : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	USceneComponent AttachmentComp;
	EDentistBossTool ToolType;
	EDentistBossArm AttachmentArm;

	ADentistBoss Dentist;
	bool bActive = false;
	bool bDestroyed = false;
	bool bIsMoving = false;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Dentist = TListedActors<ADentistBoss>().Single;
	}	

	UFUNCTION()
	void Activate()
	{
		bActive = true;
	}

	UFUNCTION()
	void Deactivate()
	{
		bActive = false;
	}

	void Reset()
	{
		bDestroyed = false;
		RemoveActorDisable(this);
	}

	void GetDestroyed()
	{
		bDestroyed = true;
		AddActorDisable(this);
	}
};