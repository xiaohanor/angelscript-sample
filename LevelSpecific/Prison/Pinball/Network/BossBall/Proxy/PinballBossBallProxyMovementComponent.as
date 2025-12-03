UCLASS(NotBlueprintable)
class UPinballBossBallProxyMovementComponent : UPinballProxyMovementComponent
{
	void InitMovementState(FPinballBossBallSyncedMovementData SyncedData)
	{
		OverrideGroundContact(SyncedData.GroundContact, FInstigator(this, n"InitMovementState"));

		if(SyncedData.GroundContact.IsValidBlockingHit())
			CurrentContacts.GroundContact.bIsWalkable = true;
		
		UpdateAutoGroundFollow();

		ProxyLastMoveFrame = 0;
	}

#if !RELEASE
	void LogInitial(FTemporalLog InitialLog) const override
	{
		Super::LogInitial(InitialLog);
	}

	void LogPostTick(FTemporalLog SubframeLog) const override
	{
		Super::LogPostTick(SubframeLog);
	}
#endif
};