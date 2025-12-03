struct FSanctuaryBloodGateSinglePlayerEffectEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player = nullptr;
}

struct FSanctuaryBloodGateBothPlayersEffectEventData
{
	UPROPERTY()
	AHazePlayerCharacter Mio = nullptr;
	UPROPERTY()
	AHazePlayerCharacter Zoe = nullptr;
}

class USanctuaryBloodGateEffectEventHandler : UHazeEffectEventHandler
{
	private ASanctuaryBloodGate OwningGate;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		OwningGate = Cast<ASanctuaryBloodGate>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DarkPortalEngage(FSanctuaryBloodGateSinglePlayerEffectEventData Data) 
	{
		//PrintToScreen("Trigger DarkPortalEngage", 5.0, ColorDebug::Bubblegum);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DarkPortalDisengage(FSanctuaryBloodGateSinglePlayerEffectEventData Data) 
	{
		//PrintToScreen("Trigger DarkPortalDisengage", 5.0, ColorDebug::Bubblegum);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LightBirdEngage(FSanctuaryBloodGateSinglePlayerEffectEventData Data) 
	{
		//PrintToScreen("Trigger LightBirdEngage", 5.0, ColorDebug::Bubblegum);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LightBirdDisengage(FSanctuaryBloodGateSinglePlayerEffectEventData Data) 
	{
		//PrintToScreen("Trigger LightBirdDisengage", 5.0, ColorDebug::Bubblegum);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DarkPortalStartTurning(FSanctuaryBloodGateBothPlayersEffectEventData Data) 
	{
		//PrintToScreen("Trigger DarkPortalStartTurning", 5.0, ColorDebug::Bubblegum);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DarkPortalStopTurning(FSanctuaryBloodGateBothPlayersEffectEventData Data) 
	{
		//PrintToScreen("Trigger DarkPortalStopTurning", 5.0, ColorDebug::Bubblegum);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LightBirdStartTurning(FSanctuaryBloodGateBothPlayersEffectEventData Data) 
	{
		//PrintToScreen("Trigger LightBirdStartTurning", 5.0, ColorDebug::Bubblegum);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LightBirdStopTurning(FSanctuaryBloodGateBothPlayersEffectEventData Data) 
	{
		//PrintToScreen("Trigger LightBirdStopTurning", 5.0, ColorDebug::Bubblegum);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AlignInnerWithOuterWheel(FSanctuaryBloodGateBothPlayersEffectEventData Data) 
	{
		//PrintToScreen("Trigger AlignInnerWithOuterWheel", 5.0, ColorDebug::Bubblegum);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void UnalignInnerWithOuterWheel(FSanctuaryBloodGateBothPlayersEffectEventData Data) 
	{
		//PrintToScreen("Trigger UnalignInnerWithOuterWheel", 5.0, ColorDebug::Bubblegum);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AlignOuterWithBlood(FSanctuaryBloodGateBothPlayersEffectEventData Data) 
	{
		//PrintToScreen("Trigger AlignOuterWithBlood", 5.0, ColorDebug::Bubblegum);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void UnalignOuterWithBlood(FSanctuaryBloodGateBothPlayersEffectEventData Data) 
	{
		//PrintToScreen("Trigger UnalignOuterWithBlood", 5.0, ColorDebug::Bubblegum);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BloodFlowStart(FSanctuaryBloodGateBothPlayersEffectEventData Data) 
	{
		//PrintToScreen("Trigger BloodFlowStart", 5.0, ColorDebug::Bubblegum);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GateUnlock(FSanctuaryBloodGateBothPlayersEffectEventData Data) 
	{
		//PrintToScreen("Trigger GateUnlock", 5.0, ColorDebug::Bubblegum);
	}

	UFUNCTION(BlueprintPure)
	float GetVelocityInnerWheel()
	{
		return Math::Abs(OwningGate.SmallRotComp.Velocity);
	}

	UFUNCTION(BlueprintPure)
	float GetVelocityOuterWheel()
	{
		return Math::Abs(OwningGate.BigRotComp.Velocity);
	}

	UFUNCTION(BlueprintPure)
	float GetVelocityForWheelsCombined()
	{
		return GetVelocityInnerWheel() + GetVelocityOuterWheel();
	}

}