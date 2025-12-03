UCLASS(Abstract, HideCategories = "ComponentTick Activation Cooking Debug Disable Tags Collision")
class UJetskiDriverComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditDefaultsOnly)
	protected TSubclassOf<AJetski> JetskiClass;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSettingsDataAsset CameraSettings;

	AHazePlayerCharacter Player;
	AJetski Jetski;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	AJetski GetOrCreateJetski()
	{
		if(Jetski == nullptr)
			SpawnJetski();

		return Jetski;
	}

	void SpawnJetski()
	{
		if(Jetski != nullptr)
			return;

		if(!devEnsure(JetskiClass.IsValid()))
			return;

		FString PlayerName = Player.IsMio() ? "Mio" : "Zoe";
		FString JetskiName = "Jetski_" + PlayerName;

		Jetski = SpawnActor(JetskiClass, Player.ActorLocation, Player.ActorRotation, FName(JetskiName), true);

#if EDITOR
		Jetski.SetActorLabel(JetskiName);
#endif

		if(Jetski == nullptr)
			return;

		Jetski.MakeNetworked(this, FName(JetskiName));
		Jetski.SetActorControlSide(Player);

		FinishSpawningActor(Jetski);

		Jetski.SetDriver(Player);
		Jetski.AddActorDisable(this);
	}

	void ActivateJetski()
	{
		Jetski.JetskiSpline = Jetski::GetJetskiSpline();
		check(Jetski.JetskiSpline != nullptr, "Activated Jetski without a valid spline to follow!");
		Jetski.RemoveActorDisable(this);

		if(!Jetski.bIsControlledByCutscene)
			Jetski.SetActorLocationAndRotation(Player.ActorLocation, Player.ActorRotation, true);

		Jetski.AttachSoundDefs();
	}

	void DeactivateJetski()
	{
		Jetski.RemoveSoundDefs();
		Jetski.AddActorDisable(this);
	}
};