struct FSwarmDroneHoverZonePlayerParams
{
	FSwarmDroneHoverZonePlayerParams(AHazePlayerCharacter InPlayer)
	{
		Player = InPlayer;
	}

	UPROPERTY()
	AHazePlayerCharacter Player = nullptr;
}

class USwarmDroneHoverZoneEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	ADroneSwarmHoverZone HoverZone;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverZone = Cast<ADroneSwarmHoverZone>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEnabled() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDisabled() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerEnter(FSwarmDroneHoverZonePlayerParams EnterParams) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerExit(FSwarmDroneHoverZonePlayerParams ExitParams) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SwarmDroneHoveringStart() { }

	UFUNCTION(BlueprintPure)
	bool IsPlayerInside() const
	{
		return HoverZone.IsPlayerInsideZone();
	}

	UFUNCTION(BlueprintPure)
	float GetNormalPlayerDistanceToBottom() const
	{
		AHazePlayerCharacter PlayerInZone = HoverZone.GetCurrentPlayerInsideZone();
		if (PlayerInZone != nullptr)
			return HoverZone.GetMoveFractionAtLocation(PlayerInZone.ActorLocation);

		return 0;
	}

	UFUNCTION(BlueprintPure)
	float GetNormalPlayerDistanceToTop() const
	{
		return 1.0 - GetNormalPlayerDistanceToBottom();
	}
}