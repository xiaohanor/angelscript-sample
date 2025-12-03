UCLASS(Abstract)
class UPinballMagnetDroneComponent : UActorComponent
{
	AHazePlayerCharacter Player;

	UPinballMovementSettings MovementSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MovementSettings = UPinballMovementSettings::GetSettings(Player);

		auto BallComp = UPinballBallComponent::Get(Player);
		BallComp.OnSquished.AddUFunction(this, n"OnSquished");

#if !RELEASE
		TEMPORAL_LOG(this, Owner, "PinballMagnetDrone");
#endif
	}

	UFUNCTION()
	private void OnSquished()
	{
		Player.KillPlayer();
	}
}