
UCLASS(Abstract)
class UVO_Centipede_Shared_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnBurningStopped(){}

	UFUNCTION(BlueprintEvent)
	void OnBurningStarted(){}

	UFUNCTION(BlueprintEvent)
	void OnStretchStop(){}

	UFUNCTION(BlueprintEvent)
	void OnStretchStart(){}

	UFUNCTION(BlueprintEvent)
	void OnSwingPointReleased(FSanctuaryCentipedeSwingpointEventData SanctuaryCentipedeSwingpointEventData){}

	UFUNCTION(BlueprintEvent)
	void OnSwingPointAttached(FSanctuaryCentipedeSwingpointEventData SanctuaryCentipedeSwingpointEventData){}

	UFUNCTION(BlueprintEvent)
	void OnDetachWaterOutlet(FCentipedeWaterOutletEventParams CentipedeWaterOutletEventParams){}

	UFUNCTION(BlueprintEvent)
	void OnAttachWaterOutlet(FCentipedeWaterOutletEventParams CentipedeWaterOutletEventParams){}

	UFUNCTION(BlueprintEvent)
	void OnGateChainReleased(FSanctuaryCentipedeGateChainReleasedData SanctuaryCentipedeGateChainReleasedData){}

	UFUNCTION(BlueprintEvent)
	void OnGateChainGrabbed(FSanctuaryCentipedeGateChainGrabbedData SanctuaryCentipedeGateChainGrabbedData){}

	UFUNCTION(BlueprintEvent)
	void OnBiteStopped(FSanctuaryCentipedeBiteEventData SanctuaryCentipedeBiteEventData){}

	UFUNCTION(BlueprintEvent)
	void OnBiteStarted(FSanctuaryCentipedeBiteEventData SanctuaryCentipedeBiteEventData){}

	UFUNCTION(BlueprintEvent)
	void OnCentipedeStretchStop(){}

	UFUNCTION(BlueprintEvent)
	void OnCentipedeStretchStart(){}

	UFUNCTION(BlueprintEvent)
	void OnUpdateBurning(FSanctuaryCentipedeBurningEventEventData SanctuaryCentipedeBurningEventEventData){}

	UFUNCTION(BlueprintEvent)
	void OnBurningDeath(){}

	UFUNCTION(BlueprintEvent)
	void OnBiteResponseComponentBitten(){}

	UFUNCTION(BlueprintEvent)
	void OnBiteAnticipationStopped(FCentipedeBiteEventParams CentipedeBiteEventParams){}

	UFUNCTION(BlueprintEvent)
	void OnBiteAnticipationStarted(FCentipedeBiteEventParams CentipedeBiteEventParams){}

	UFUNCTION(BlueprintEvent)
	void OnSwingPointIdling(FSanctuaryCentipedeBiteEventData SanctuaryCentipedeBiteEventData){}

	UFUNCTION(BlueprintEvent)
	void SanctuaryLavamole_OnTornApart(){}

	UFUNCTION(BlueprintEvent)
	void SanctuaryLavamole_OnWhacked(){}

	UFUNCTION(BlueprintEvent)
	void SanctuaryLavamole_OnMortarTelegraph(FSanctuaryLavamoleOnMortarTelegraphEventData SanctuaryLavamoleOnMortarTelegraphEventData){}

	UFUNCTION(BlueprintEvent)
	void SanctuaryLavamole_OnBoulderAttack(){}

	UFUNCTION(BlueprintEvent)
	void SanctuaryLavamole_OnBoulderTelegraph(FSanctuaryLavamoleOnBoulderTelegraphEventData SanctuaryLavamoleOnBoulderTelegraphEventData){}

	UFUNCTION(BlueprintEvent)
	void SanctuaryLavamole_OnDeath(){}

	UFUNCTION(BlueprintEvent)
	void SanctuaryLavamole_OnDigDown(){}

	UFUNCTION(BlueprintEvent)
	void SanctuaryLavamole_OnDigUp(){}

	UFUNCTION(BlueprintEvent)
	void SanctuaryLavamole_OnAnticipateUp(FSanctuaryLavamoleOnOnAnticipateUpEventData SanctuaryLavamoleOnOnAnticipateUpEventData){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintPure)
	float GetDraggableAlpha(UCentipedeDraggableChainComponent DraggableComp) const
	{
		if (IsValid(DraggableComp))
			return DraggableComp.DraggedAlpha;

		return 0;
	}
}