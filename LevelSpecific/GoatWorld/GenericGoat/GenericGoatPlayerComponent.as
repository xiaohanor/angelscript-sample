class UGenericGoatPlayerComponent : UActorComponent
{
	AHazePlayerCharacter Player;

	UPROPERTY()
	TSubclassOf<AGenericGoat> GoatClass;
	AGenericGoat CurrentGoat;

	UPROPERTY()
	UAnimSequence MountAnim;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	UPROPERTY()
	UNiagaraSystem SprintSystem;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		CurrentGoat = SpawnActor(GoatClass, Player.ActorLocation, Player.ActorRotation);
		CurrentGoat.AttachToComponent(Player.MeshOffsetComponent);
		CurrentGoat.MountedPlayer = Player;
	}
}