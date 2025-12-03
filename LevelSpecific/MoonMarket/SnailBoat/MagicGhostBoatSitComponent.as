class UMagicGhostBoatSitComponent : UActorComponent
{
	AMagicGhostBoat Boat;
	UInteractionComponent InteractComp;
	bool bIsSitting = false;

	void Sit(AMagicGhostBoat InBoat, UInteractionComponent InInteractComp)
	{
		Boat = InBoat;
		InteractComp = InInteractComp;
		bIsSitting = true;
	}

	void StopSitting()
	{
		Boat = nullptr;
		InteractComp = nullptr;
		bIsSitting = false;
	}
};