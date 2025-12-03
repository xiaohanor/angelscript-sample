struct FIceBowShootRopeOnActivateParams
{
    FVector Direction;
	FVector TargetLocation;
    float ChargeFactor;
    FVector Velocity;
}

/**
 * 
 */
class UIceBowShootRopeCapability : UHazePlayerCapability
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
	URopeArrowPlayerComponent RopeArrowPlayerComp;
	UProjectileProximityManagerComponent ProjectileProximityComp;

	// needs to activate after the charging capability
	default TickGroupOrder = 107;

	default TickGroup = EHazeTickGroup::Movement;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        IceBowPlayerComp = UIceBowPlayerComponent::Get(Player);
		RopeArrowPlayerComp = URopeArrowPlayerComponent::Get(Player);
		ProjectileProximityComp = UProjectileProximityManagerComponent::GetOrCreate(Player);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate(FIceBowShootRopeOnActivateParams& Params) const
    {
        if (!IceBowPlayerComp.GetIsAiming())
            return false;

        if(!IceBowPlayerComp.IsFullyCharged())
            return false;

		if(IsActioning(IceBow::ShotAction))
            return false;

        FIceBowTargetData TargetData = IceBowPlayerComp.CalculateTargetData(EIceBowArrowType::Rope);
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
    void OnActivated(FIceBowShootRopeOnActivateParams Params)
    {
		Player.BlockCapabilities(WindJavelin::WindJavelinTag, this);

        // Spawn and launch rope arrow
        const FVector Location = IceBowPlayerComp.GetArrowSpawnLocation();
        const FRotator Rotation = FRotator::MakeFromX(Params.Direction);

		if(IsValid(RopeArrowPlayerComp.CurrentArrow))
        {
			RopeArrowPlayerComp.CurrentArrow.Deactivate();
            RopeArrowPlayerComp.CurrentArrow.SetActorLocationAndRotation(Location, Rotation);
        }
        else
        {
            ARopeArrow RopeArrow = Cast<ARopeArrow>(SpawnActor(RopeArrowPlayerComp.RopeArrowClass, Location, Rotation, NAME_None, true));
            RopeArrow.MakeNetworked(this, n"RopeArrow");
			RopeArrow.Player = Player;
            FinishSpawningActor(RopeArrow);

		    RopeArrowPlayerComp.CurrentArrow = RopeArrow;
        }

        IceBowPlayerComp.SetChargeFactor(Params.ChargeFactor);
        const float ArrowGravity = RopeArrowPlayerComp.Settings.Gravity;

        USceneComponent AttachComponent;
        FVector AttachLocation;
        if(GetRopeEndAttach(Params.Direction, AttachComponent, AttachLocation))
        {
            RopeArrowPlayerComp.CurrentArrow.CableComp.bAttachEnd = true;
            RopeArrowPlayerComp.CurrentArrow.CableComp.SetAttachEndToComponent(AttachComponent);
            FVector RelativeAttachLocation = AttachComponent.WorldTransform.InverseTransformPosition(AttachLocation);
            RopeArrowPlayerComp.CurrentArrow.CableComp.EndLocation = RelativeAttachLocation;
            RopeArrowPlayerComp.CurrentArrow.CableComp.CableLength = AttachLocation.Distance(Params.TargetLocation) / 5;
        }
        else
        {
            RopeArrowPlayerComp.CurrentArrow.CableComp.SetVisibility(false);
        }

        RopeArrowPlayerComp.CurrentArrow.Launch(Params.Velocity, ArrowGravity, ProjectileProximityComp);

        // Trigger events
        FRopeArrowLaunchEventData RopeLaunchData;
        RopeLaunchData.LaunchImpulse = Params.Velocity;
		//UIceBowEventHandler::Trigger_LaunchRopeArrow(Player, RopeLaunchData);
        // RopeArrowPlayerComp.CurrentArrow.TriggerEffectEvent(n"RopeArrow.Launch", RopeLaunchData); // UNKNOWN EFFECT EVENT NAMESPACE

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

    private bool GetRopeEndAttach(FVector AimDirection, USceneComponent& OutAttachComponent, FVector& OutAttachLocation)
    {
        FHazeTraceSettings Settings = RopeArrowPlayerComp.CurrentArrow.GetTraceSettings();

        FVector Start = IceBowPlayerComp.GetArrowSpawnLocation();
        FVector End = Start - (AimDirection * 10000);

        FHitResult Hit = Settings.QueryTraceSingle(
			Start,
			End
		);

        #if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
        TemporalLog.HitResults("GetRopeEndAttachBack", Hit, FHazeTraceShape::MakeSphere(RopeArrowPlayerComp.CurrentArrow.Sphere.SphereRadius));
        #endif

        if(Hit.bBlockingHit)
        {
            OutAttachComponent = Hit.Component;
            OutAttachLocation = Hit.ImpactPoint;
            return true;
        }
        else
        {
            Settings = RopeArrowPlayerComp.CurrentArrow.GetTraceSettings();

            Start = Player.ActorCenterLocation;
            End = Start - (FVector::UpVector * 10000);

            Hit = Settings.QueryTraceSingle(
                Start,
                End
		    );

            #if EDITOR
            TemporalLog.HitResults("GetRopeEndAttachDown", Hit, FHazeTraceShape::MakeSphere(RopeArrowPlayerComp.CurrentArrow.Sphere.SphereRadius));
            #endif

            if(Hit.bBlockingHit)
            {
                OutAttachComponent = Hit.Component;
                OutAttachLocation = Hit.ImpactPoint;
                return true;
            }
            else
            {
                return false;
            }
        }
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