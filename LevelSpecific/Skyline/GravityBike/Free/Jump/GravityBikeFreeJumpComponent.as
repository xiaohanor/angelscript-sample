UCLASS(NotBlueprintable)
class UGravityBikeFreeJumpComponent : UActorComponent
{
	private AGravityBikeFree GravityBike;
	UGravityBikeFreeJumpSettings Settings;

	TArray<UGravityBikeFreeJumpTriggerComponent> JumpTriggers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		Settings = UGravityBikeFreeJumpSettings::GetSettings(GravityBike);
	}
};