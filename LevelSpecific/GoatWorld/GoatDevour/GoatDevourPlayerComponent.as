class UGoatDevourPlayerComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<AGoatDevourGoatActor> GoatClass;
	AGoatDevourGoatActor CurrentGoat;

	UPROPERTY()
	FAimingSettings AimSettings;

	AHazePlayerCharacter Player;

	UGoatDevourResponseComponent CurrentDevourResponseComp;
	UGoatDevourPlacementComponent CurrentPlacementComp;
	UGenericGoatPlayerComponent GoatComp;
	
	bool bMouthOpen = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		GoatComp = UGenericGoatPlayerComponent::Get(Player);
		GoatComp.CurrentGoat.AddActorDisable(this);

		AGoatDevourGoatActor GoatActor = SpawnActor(GoatClass);
		GoatComp.CurrentGoat = GoatActor;
		GoatActor.AttachToComponent(Player.MeshOffsetComponent);
		GoatActor.MountedPlayer = Player;
		CurrentGoat = GoatActor;
	}

	void OpenMouth()
	{
		bMouthOpen = true;
		CurrentGoat.OpenMouth();
	}

	void CloseMouth()
	{
		bMouthOpen = false;
		CurrentGoat.CloseMouth();
	}
}