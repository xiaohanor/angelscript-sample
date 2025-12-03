
UCLASS(Abstract)
class UVO_Skyline_SideContent_SwimmingRings_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditInstanceOnly)
	ASkylineSwimmingRing SwimmingRingA;

	UPROPERTY(EditInstanceOnly)
	ASkylineSwimmingRing SwimmingRingB;

	UPROPERTY(EditInstanceOnly)
	ASkylineSwimmingRing SwimmingRingC;

	TArray<AHazePlayerCharacter> PlayersInside;

	UFUNCTION(BlueprintPure)
	bool AreBothPlayersInRings() const
	{
		return PlayersInside.Num() == 2;
	}

	UFUNCTION(BlueprintPure)
	bool IsPlayerInRing(AHazePlayerCharacter Player) const
	{
		return PlayersInside.Contains(Player);
	}

	UFUNCTION()
	void OnPlayerEnterJumpIntoFromAbove(FSkylineSwimmingRingEventData SkylineSwimmingRingEventData)
	{
		PlayersInside.Add(SkylineSwimmingRingEventData.Player);
		
		if (AreBothPlayersInRings())
			OnBothPlayersInRings();
	}

	UFUNCTION()
	void OnPlayerEnterSwimIntoFromBelow(FSkylineSwimmingRingEventData SkylineSwimmingRingEventData)
	{
		PlayersInside.Add(SkylineSwimmingRingEventData.Player);

		if (AreBothPlayersInRings())
			OnBothPlayersInRings();
	}

	UFUNCTION()
	void OnPlayerLeaveJumpOut(FSkylineSwimmingRingEventData SkylineSwimmingRingEventData)
	{
		PlayersInside.Remove(SkylineSwimmingRingEventData.Player);
	}

	UFUNCTION(BlueprintEvent)
	void OnBothPlayersInRings() {}
}