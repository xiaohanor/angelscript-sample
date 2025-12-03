UCLASS(NotBlueprintable)
class UPinballBallRailComponent : UActorComponent
{
	UFUNCTION(BlueprintPure)
	bool IsPlayer() const
	{
		return Owner.IsA(AHazePlayerCharacter);
	}

	void EnterRail(APinballRail InRail, EPinballRailHeadOrTail InEnterSide)
	{
	}
};