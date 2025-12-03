UCLASS(Abstract)
class USketchbookBowPlayerEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player = nullptr;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	USketchbookBowPlayerComponent PlayerComp = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = USketchbookBowPlayerComponent::Get(Player);
		check(PlayerComp != nullptr);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartAiming() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopAiming() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartDrawingBow() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinishedCharging() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LaunchArrow(FSketchbookArrowLaunchEventData LaunchData) { }
}

struct FSketchbookArrowLaunchEventData
{
	UPROPERTY()
	FVector LaunchImpulse;

	UPROPERTY()
	float ChargeFactor;
}