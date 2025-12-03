class UGravityBikeSplinePassengerAttachCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = -90;

	default CapabilityTags.Add(CapabilityTags::BlockedByCutscene);

	UGravityBikeSplinePassengerComponent PassengerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PassengerComp = UGravityBikeSplinePassengerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Player.bIsParticipatingInCutscene)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Player.bIsParticipatingInCutscene)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.AttachToComponent(PassengerComp.GravityBike.PassengerAttachment);
		PassengerComp.OnPlayerMounted.Broadcast(PassengerComp.GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DetachFromActor();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!Player.Mesh.CanRequestLocomotion())
            return;

        Player.Mesh.RequestLocomotion(GravityBikeSpline::GravityBikeSplinePlayerFeature, this);
	}
};