/**
 * When a player goes inside this trigger, any ground will be considered unwalkable, making us slide.
 */
UCLASS(NotBlueprintable)
class UPlayerUnwalkableTriggerComponent : UHazeMovablePlayerTriggerComponent
{
#if EDITOR
	default ShapeColor = FLinearColor::DPink;
#endif

	access EditAndReadOnly = private, * (editdefaults, readonly);

	UPROPERTY(EditAnywhere, Category = "Unwalkable Trigger")
	access:EditAndReadOnly bool bUnwalkable = true;

	UPROPERTY(EditAnywhere, Category = "Unwalkable Trigger")
	access:EditAndReadOnly EHazeSettingsPriority Priority = EHazeSettingsPriority::Gameplay;

	UFUNCTION(BlueprintOverride)
	void OnPlayerEnteredTrigger(AHazePlayerCharacter Player)
	{
		UMovementStandardSettings::SetForceAllGroundUnwalkable(Player, bUnwalkable, this, Priority);
	}

	UFUNCTION(BlueprintOverride)
	void OnPlayerLeftTrigger(AHazePlayerCharacter Player)
	{
		UMovementStandardSettings::ClearForceAllGroundUnwalkable(Player, this, Priority);
	}
};