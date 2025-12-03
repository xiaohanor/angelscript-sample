class UCoastBossAeronauticDashCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default CapabilityTags.Add(PlayerMovementTags::AirDash);

	default TickGroup = EHazeTickGroup::Gameplay;
	UCoastBossAeronauticComponent AirMoveDataComp;
	UPlayerAirDashComponent AirDashComp;
	ACoastBossActorReferences References;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TListedActors<ACoastBossActorReferences> LevelReferencesActor;
		References = LevelReferencesActor.Single;
		AirMoveDataComp = UCoastBossAeronauticComponent::GetOrCreate(Owner);
		AirDashComp = UPlayerAirDashComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AirMoveDataComp.bAttached)
			return false;
		if (DeactiveDuration < CoastBossConstants::Player::DashCooldown)
			return false;
		if (WasActionStartedDuringTime(ActionNames::MovementDash, AirDashComp.Settings.InputBufferWindow))
			return true;
#if !RELEASE
		if (DevTogglesMovement::Dash::AutoAlwaysDash.IsEnabled(Player))
			return true;
#endif
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FCoastBossAeronauticDashEffectData Data;
		Data.Drone = AirMoveDataComp.AttachedToShip;
		Data.PlaneToAttachTo = References.CoastBossPlane2D.RootComponent;
		Data.Player = Player;
		UCoastBossAeuronauticPlayerEventHandler::Trigger_OnDash(Player, Data);
		AirMoveDataComp.AccDashAlpha.SnapTo(1.0);

		Player.PlayForceFeedback(AirMoveDataComp.FFDash, false, true, this);
	}
};