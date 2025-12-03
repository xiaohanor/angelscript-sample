event void FGravityBikeFreeDriverOnMounted(AGravityBikeFree GravityBike);

UCLASS(Abstract)
class UGravityBikeFreeDriverComponent : UActorComponent
{
	access Protected = protected, AGravityBikeFree (inherited);

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AGravityBikeFree> GravityBikeClass;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY()
	FGravityBikeFreeDriverOnMounted OnMounted;

	private AHazePlayerCharacter Player;
    private AGravityBikeFree GravityBike;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	AGravityBikeFree GetOrSpawnGravityBike()
	{
		if(GravityBike != nullptr)
			return GravityBike;

		if(!devEnsure(GravityBikeClass.IsValid()))
			return nullptr;

		FName GravityBikeName = Player.Player == EHazePlayer::Mio ? n"GravityBikeFree_Mio" : n"GravityBikeFree_Zoe";
		
		GravityBike = SpawnActor(
			GravityBikeClass,
			Player.ActorLocation,
			Player.ActorRotation,
			GravityBikeName,
			true
		);

#if EDITOR
		GravityBike.SetActorLabel(GravityBikeName.ToString());
#endif

		GravityBike.MakeNetworked(this, GravityBikeName);
		GravityBike.SetActorControlSide(Player);
		GravityBike.SetDriver(Player);

		FinishSpawningActor(GravityBike);

		GravityBike.MoveComp.Reset(false, bValidateGround = true);

		return GravityBike;
	}

	AGravityBikeFree GetGravityBike() const
	{
		check(GravityBike != nullptr, "Gravity Bike has not been spawned yet! Call GetOrSpawnGravityBike instead!");
		return GravityBike;
	}
}