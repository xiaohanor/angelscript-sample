/**
 * While the player is in this trigger, their network sync is relative to the trigger's location.
 */
UCLASS(NotBlueprintable)
class UPlayerCrumbSyncRelativeComponent : UHazeMovablePlayerTriggerComponent
{	
	UPROPERTY(EditAnywhere, Category = "Relative Sync")
	bool bApplyToRotation = true;
	UPROPERTY(EditAnywhere, Category = "Relative Sync")
	EInstigatePriority Priority = EInstigatePriority::Normal;

	UFUNCTION(BlueprintOverride)
	void OnPlayerEnteredTrigger(AHazePlayerCharacter Player)
	{
		auto MoveComp = UHazeMovementComponent::Get(Player);
		MoveComp.ApplyCrumbSyncedRelativePosition(
			this, this,
			Priority = Priority, bRelativeRotation = bApplyToRotation
		);
	}

	UFUNCTION(BlueprintOverride)
	void OnPlayerLeftTrigger(AHazePlayerCharacter Player)
	{
		auto MoveComp = UHazeMovementComponent::Get(Player);
		MoveComp.ClearCrumbSyncedRelativePosition(this);
	}

}