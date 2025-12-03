/**
 * Player events for the single-player cannon.
 * Currently unused!
 */
UCLASS(Abstract)
class UDentistToothCannonEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(BlueprintReadOnly)
	UDentistToothPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartLaunched() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopLaunched() {}

	UFUNCTION(BlueprintPure)
	ADentistTooth GetToothActor() const
	{
		return PlayerComp.GetToothActor();
	}

	UFUNCTION(BlueprintPure)
	FVector GetCenterOfToothTipsLocation() const
	{
		return (Player.Mesh.GetSocketLocation(n"LeftFoot") + Player.Mesh.GetSocketLocation(n"RightFoot")) / 2;
	}
};