/**
 * Inherit from this class and override the events you want.
 * The ice bow will call these events at various places.
 */
UCLASS(Abstract)
class UIceBowEventHandler : UHazeEffectEventHandler
{

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player = nullptr;

	UPROPERTY(BlueprintReadOnly)
	UIceBowPlayerComponent PlayerComp = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Game::GetPlayer(IceBow::Player);
		PlayerComp = UIceBowPlayerComponent::Get(Player);
		check(PlayerComp != nullptr);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartAiming() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopAiming() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartDrawingBow() { }

	/**
	 * Arrow is fully charged (blizzard instead of ice)
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinishedCharging() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LaunchIceArrow(FIceArrowLaunchEventData LaunchData) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LaunchBlizzardArrow(FBlizzardArrowLaunchEventData LaunchData) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LaunchWindArrow(FWindArrowLaunchEventData LaunchData) { }
}

struct FIceArrowLaunchEventData
{
	UPROPERTY()
	FVector LaunchImpulse;

	UPROPERTY()
	float ChargeFactor;
}

struct FWindArrowLaunchEventData
{
	UPROPERTY()
	FVector LaunchImpulse;

	UPROPERTY()
	float ChargeFactor;
}

struct FBlizzardArrowLaunchEventData
{
	UPROPERTY()
	FVector LaunchImpulse;
}

struct FRopeArrowLaunchEventData
{
	UPROPERTY()
	FVector LaunchImpulse;
}