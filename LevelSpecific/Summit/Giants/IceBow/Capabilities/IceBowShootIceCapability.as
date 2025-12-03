struct FIceBowShootIceOnActivateParams
{
    FVector Direction;
	FVector TargetLocation;
    float ChargeFactor;
    FVector Velocity;
}

/**
 * 
 */
class UIceBowShootIceCapability : UHazePlayerCapability
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

    FIceBowShootIceOnActivateParams ActivatedParams;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        IceBowPlayerComp = UIceBowPlayerComponent::Get(Player);
		IceArrowPlayerComp = UIceArrowPlayerComponent::Get(Player);
		ProjectileProximityComp = UProjectileProximityManagerComponent::GetOrCreate(Player);
		IceArrowPlayerComp.IceArrowPool.OnSpawnedBySpawner.FindOrAdd(IceArrowPlayerComp).AddUFunction(this, n"OnIceArrowSpawned");
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate(FIceBowShootIceOnActivateParams& Params) const
    {
        if (!IceBowPlayerComp.GetIsAiming())
            return false;

        if(IceBowPlayerComp.GetChargeFactor() < IceBowPlayerComp.BowSettings.MinimumCharge)
            return false;

        if(IceBowPlayerComp.IsFullyCharged())
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
    void OnActivated(FIceBowShootIceOnActivateParams Params)
    {
        ActivatedParams = Params;

		Player.BlockCapabilities(WindJavelin::WindJavelinTag, this);

        // Spawn and launch ice arrow

        if (HasControl())
        {
            FHazeActorSpawnParameters SpawnParams(IceArrowPlayerComp);
            SpawnParams.Location = IceBowPlayerComp.GetArrowSpawnLocation();
            SpawnParams.Rotation = FRotator::MakeFromX(ActivatedParams.Direction);
			IceArrowPlayerComp.ReadyProjectile_Control(SpawnParams);
        }

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
    
	UFUNCTION(NotBlueprintCallable)
	private void OnIceArrowSpawned(AHazeActor SpawnedActor, FHazeActorSpawnParameters Params)
	{
		AIceArrow IceArrow = Cast<AIceArrow>(SpawnedActor);
        
		IceArrow.Activate();

        IceBowPlayerComp.SetChargeFactor(ActivatedParams.ChargeFactor);
        IceArrow.ChargeFactor = ActivatedParams.ChargeFactor;
        const float ArrowGravity = IceArrowPlayerComp.GetArrowGravity();

        IceArrow.Launch(ActivatedParams.Velocity, ArrowGravity, ProjectileProximityComp, IceArrowPlayerComp);

        // Trigger events
        FIceArrowLaunchEventData LaunchData;
        LaunchData.LaunchImpulse = ActivatedParams.Velocity;
        LaunchData.ChargeFactor = IceBowPlayerComp.GetChargeFactor();
        UIceBowEventHandler::Trigger_LaunchIceArrow(Player, LaunchData);
        UIceArrowEventHandler::Trigger_Launch(IceArrow, LaunchData);
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