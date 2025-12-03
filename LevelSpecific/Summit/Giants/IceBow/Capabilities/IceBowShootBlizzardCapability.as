struct FIceBowShootBlizzardOnActivateParams
{
    FVector Direction;
	FVector TargetLocation;
    float ChargeFactor;
    FVector Velocity;
}

/**
 * 
 */
class UIceBowShootBlizzardCapability : UHazePlayerCapability
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
	UBlizzardArrowPlayerComponent BlizzardArrowComp;
	UProjectileProximityManagerComponent ProjectileProximityComp;

	// needs to activate after the charging capability
	default TickGroupOrder = 107;

	default TickGroup = EHazeTickGroup::Movement;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        IceBowPlayerComp = UIceBowPlayerComponent::Get(Player);
        BlizzardArrowComp = UBlizzardArrowPlayerComponent::Get(Player);
		ProjectileProximityComp = UProjectileProximityManagerComponent::GetOrCreate(Player);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate(FIceBowShootBlizzardOnActivateParams& Params) const
    {
        if (!IceBowPlayerComp.GetIsAiming())
            return false;

        if(!IceBowPlayerComp.IsFullyCharged())
            return false;

		if(IsActioning(IceBow::ShotAction))
            return false;

        FIceBowTargetData TargetData = IceBowPlayerComp.CalculateTargetData(EIceBowArrowType::Blizzard);
        Params.Direction = TargetData.GetDirection();
        Params.TargetLocation = TargetData.TargetLocation;
        Params.ChargeFactor = 1.0;
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
    void OnActivated(FIceBowShootBlizzardOnActivateParams Params)
    {
		Player.BlockCapabilities(WindJavelin::WindJavelinTag, this);

        // Spawn and launch blizzard arrow
        FVector Location = IceBowPlayerComp.GetArrowSpawnLocation();
        FRotator Rotation = FRotator::MakeFromX(Params.Direction);

		if(IsValid(BlizzardArrowComp.CurrentArrow))
        {
			BlizzardArrowComp.CurrentArrow.Deactivate();
            BlizzardArrowComp.CurrentArrow.SetActorLocationAndRotation(Location, Rotation);
        }
        else
        {
            ABlizzardArrow BlizzardArrow = Cast<ABlizzardArrow>(SpawnActor(BlizzardArrowComp.BlizzardArrowClass, Location, Rotation, NAME_None, true));
            BlizzardArrow.MakeNetworked(this, n"BlizzardArrow");
			BlizzardArrow.Player = Player;
            FinishSpawningActor(BlizzardArrow);

		    BlizzardArrowComp.CurrentArrow = BlizzardArrow;
        }

        IceBowPlayerComp.SetChargeFactor(Params.ChargeFactor);
        const float ArrowGravity = BlizzardArrowComp.Settings.Gravity;

        BlizzardArrowComp.CurrentArrow.Launch(Params.Velocity, ArrowGravity, ProjectileProximityComp);

        // Trigger events
        FBlizzardArrowLaunchEventData BlizzardLaunchData;
        BlizzardLaunchData.LaunchImpulse = Params.Velocity;
		UIceBowEventHandler::Trigger_LaunchBlizzardArrow(Player, BlizzardLaunchData);
        UBlizzardArrowEventHandler::Trigger_Launch(BlizzardArrowComp.CurrentArrow, BlizzardLaunchData);

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