struct FIceBowShootOnActivateParams
{
    FVector Direction;
	FVector TargetLocation;
    float ChargeFactor;
    FVector Velocity;
}

/**
 * 
 */
class UIceBowShootCapability : UHazePlayerCapability
{
    default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
   	default DebugCategory = IceBow::DebugCategory;
    
    default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(IceBow::IceBowTag);

	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(BlockedWhileIn::Crouch);

	UIceBowPlayerComponent IceBowPlayerComp;
	UIceArrowPlayerComponent IceArrowPlayerComp;
	UProjectileProximityManagerComponent ProjectileProximityComp;

	// needs to activate after the charging capability
	default TickGroupOrder = 107;

	default TickGroup = EHazeTickGroup::Movement;

    int SpawnedArrowCounter = 0;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        IceBowPlayerComp = UIceBowPlayerComponent::Get(Player);
		IceArrowPlayerComp = UIceArrowPlayerComponent::Get(Player);
		// ProjectileProximityComp = UProjectileProximityManagerComponent::GetOrCreate(Player);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate(FIceBowShootOnActivateParams& Params) const
    {
        if (!IceBowPlayerComp.GetIsAiming())
            return false;

        if(IceBowPlayerComp.GetChargeFactor() < IceBowPlayerComp.BowSettings.MinimumCharge)
            return false;

		if(IsActioning(IceBow::ShotAction))
            return false;

        FIceBowTargetData TargetData = IceBowPlayerComp.CalculateTargetData(EIceBowArrowType::Ice);
        Params.Direction = TargetData.GetDirection();
        Params.TargetLocation = TargetData.TargetLocation;
        Params.ChargeFactor = IceBowPlayerComp.GetChargeFactor();
        Params.Velocity = TargetData.Velocity;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
		if (ActiveDuration >= BowSettings.ShootAnimDuration)
			return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FIceBowShootOnActivateParams Params)
    {
		Player.BlockCapabilities(WindJavelin::WindJavelinTag, this);

        // Spawn and launch ice arrow
        FRotator AimRot = FRotator::MakeFromX(Params.Direction);

        AIceArrow IceArrow = Cast<AIceArrow>(SpawnActor(IceArrowPlayerComp.IceArrowClass, IceBowPlayerComp.GetArrowSpawnLocation(), AimRot, NAME_None, true));
        IceArrow.MakeNetworked(this, SpawnedArrowCounter);
		IceArrow.Player = Player;
		SpawnedArrowCounter++;
        FinishSpawningActor(IceArrow);

        IceBowPlayerComp.SetChargeFactor(Params.ChargeFactor);
        IceArrow.ChargeFactor = Params.ChargeFactor;
        const float ArrowGravity = IceArrowPlayerComp.GetArrowGravity();

        IceArrow.Launch(Params.Velocity, ArrowGravity, ProjectileProximityComp, IceArrowPlayerComp);

        // Trigger events
        FIceArrowLaunchEventData LaunchData;
        LaunchData.LaunchImpulse = Params.Velocity;
        LaunchData.ChargeFactor = IceBowPlayerComp.GetChargeFactor();
		UIceBowEventHandler::Trigger_LaunchIceArrow(Player, LaunchData);
        UIceArrowEventHandler::Trigger_Launch(IceArrow, LaunchData);

        // Camera impulse
        FHazeCameraImpulse Impulse = BowSettings.LaunchCameraImpulse;
        Impulse.CameraSpaceImpulse *= IceBowPlayerComp.GetChargeFactor();
        Impulse.WorldSpaceImpulse *= IceBowPlayerComp.GetChargeFactor();
        Impulse.AngularImpulse *= IceBowPlayerComp.GetChargeFactor();
        Player.ApplyCameraImpulse(Impulse, this);

        // Camera shake
        if(BowSettings.LaunchCameraShake != nullptr)
            Player.PlayCameraShake(BowSettings.LaunchCameraShake, this, IceBowPlayerComp.GetChargeFactor());

        // Force Feedback
        if(BowSettings.LaunchForceFeedback != nullptr)
            Player.PlayForceFeedback(BowSettings.LaunchForceFeedback, false, false, this, IceBowPlayerComp.GetChargeFactor());
        
        // Reset
        IceBowPlayerComp.SetChargeFactor(0.0);
        IceBowPlayerComp.bIsFiringIceBow = true;
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
		Player.UnblockCapabilities(WindJavelin::WindJavelinTag, this);
        
        IceBowPlayerComp.bIsFiringIceBow = false;
    }

    UIceBowSettings GetBowSettings() const property
    {
        return IceBowPlayerComp.BowSettings;
    }
}