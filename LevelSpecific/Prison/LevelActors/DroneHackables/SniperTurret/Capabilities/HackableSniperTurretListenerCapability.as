class UHackableSniperTurretListenerCapability : UHazeCapability
{
	default CapabilityTags.Add(Audio::Tags::Listener);
	default CapabilityTags.Add(Audio::Tags::LevelSpecificListener);
	default TickGroup = Audio::ListenerTickGroup;

	UHazeAudioListenerComponent Listener;
	UHazeAudioReflectionComponent ReflectionComponent;

	AHackableSniperTurret SniperTurret;
	AHazePlayerCharacter Player;

	private float DistanceFromCamera = -150;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SniperTurret = Cast<AHackableSniperTurret>(Owner);
		Player = Game::GetMio();
		ReflectionComponent = UHazeAudioReflectionComponent::Get(Player);
		Listener = Player.PlayerListener;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return SniperTurret.HijackTargetableComp.IsHijacked();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !SniperTurret.HijackTargetableComp.IsHijacked();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Block the default listener
		Player.BlockCapabilities(Audio::Tags::DefaultListener, this);
		Player.BlockCapabilities(Audio::Tags::Prison::DroneListener, this);

		ReflectionComponent.AddActorToIgnore(SniperTurret);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(Audio::Tags::DefaultListener, this);
		Player.UnblockCapabilities(Audio::Tags::Prison::DroneListener, this);

		ReflectionComponent.RemoveActorToIgnore(SniperTurret);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto ActorTransform = Player.ViewTransform;
		ActorTransform.SetLocation(
			SniperTurret.MuzzleComp.WorldLocation + ActorTransform.GetRotation().ForwardVector * DistanceFromCamera
		);

		Listener.SetWorldTransform(ActorTransform);

		if (IsDebugActive() || AudioDebug::IsEnabled(EDebugAudioWorldVisualization::Players))
		{
			Audio::DebugListenerLocations(Player);
		}
	}
}