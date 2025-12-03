class UPigStretchyLegsResponseComponent : UHazeMovablePlayerTriggerComponent
{
	UFUNCTION(BlueprintOverride)
	bool CanTriggerForPlayer(AHazePlayerCharacter Player) const
	{
		UPlayerPigStretchyLegsComponent StretchyLegsComponent = UPlayerPigStretchyLegsComponent::Get(Player);
		if (StretchyLegsComponent == nullptr)
			return false;

		if (!StretchyLegsComponent.IsStretching() && !StretchyLegsComponent.IsAirborneAfterStretching())
			return false;

		// Should we check upwards velocity?

		return true;
	}
}