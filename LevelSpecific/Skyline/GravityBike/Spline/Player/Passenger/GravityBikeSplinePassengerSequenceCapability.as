class UGravityBikeSplinePassengerSequenceCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = -80;	// Tick early, but after UJetskiDriverCapability and UGravityBikeSplinePassengerAttachCapability

	UGravityBikeSplinePassengerComponent PassengerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PassengerComp = UGravityBikeSplinePassengerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Player.bIsParticipatingInCutscene)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Player.bIsParticipatingInCutscene)
			return true;

		return false;
	}
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};