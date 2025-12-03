class UPlayerSwarmDroneHoverEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable)
	UPlayerSwarmDroneComponent PlayerSwarmDroneComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerSwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHoverStart()
	{
		
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHoverStop()
	{
		
	}

	UFUNCTION(BlueprintPure)
	bool IsInsideHoverZone() const
	{
		return PlayerSwarmDroneComponent.IsInsideHoverZone();
	}

	// [0, 1] 0 is bottom if flag is true, otherwise 0 is top
	UFUNCTION(BlueprintPure)
	float GetNormalHeightInZone(bool bFromBottom = true)
	{
		// Just return first hit if there are multiple ones
		const auto& ActiveSwarmMoveZones = PlayerSwarmDroneComponent.ActiveSwarmMoveZones;
		for (auto ActiveSwarmZone : ActiveSwarmMoveZones)
		{
			if (ActiveSwarmZone.IsA(ADroneSwarmHoverZone))
			{
				float NormalHeight = ActiveSwarmZone.GetMoveFractionAtLocation(Owner.ActorLocation);
				if (!bFromBottom)
					NormalHeight = 1.0 - NormalHeight;

				return NormalHeight;
			}
		}

		return 0.0;
	}
}