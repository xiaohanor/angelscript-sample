struct FIceBowShootWindOnActivateParams
{
    FVector Direction;
}

/**
 * 
 */
class UIceBowShootWindCapability : UHazePlayerCapability
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
	UWindArrowPlayerComponent WindArrowPlayerComp;
	UProjectileProximityManagerComponent ProjectileProximityComp;
	TArray<AWindArrow> SpawnedWindArrows;

	// needs to activate after the charging capability
	default TickGroupOrder = 107;

	default TickGroup = EHazeTickGroup::Movement;

    int SpawnedArrowCounter = 0;
	bool bFullyCharged = false;
	AWindArrow CurrentWindArrow;
	bool bReleasedInput = false;
	bool bLaunched = false;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        IceBowPlayerComp = UIceBowPlayerComponent::Get(Player);
		WindArrowPlayerComp = UWindArrowPlayerComponent::Get(Player);
		// ProjectileProximityComp = UProjectileProximityManagerComponent::GetOrCreate(Player);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate(FIceBowShootWindOnActivateParams& Params) const
    {
        if (!IceBowPlayerComp.GetIsAiming())
            return false;

		if(!IsActioning(IceBow::ShotAction))
            return false;

		FIceBowTargetData TargetData = IceBowPlayerComp.CalculateTargetData(EIceBowArrowType::Wind);
        Params.Direction = TargetData.GetDirection();
        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
		if(!bReleasedInput)
			return false;

		if (bLaunched && ActiveDuration < BowSettings.ShootAnimDuration)
			return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FIceBowShootWindOnActivateParams Params)
    {
		bReleasedInput = false;
		bFullyCharged = false;
		bLaunched = false;
		Player.BlockCapabilities(WindJavelin::WindJavelinTag, this);

        // Spawn and launch wind arrow
		
        FRotator AimRot = FRotator::MakeFromX(Params.Direction);

		FVector SpawnLocation = IceBowPlayerComp.GetArrowSpawnLocation();
		SpawnLocation += AimRot.ForwardVector * 100.0;
		if(SpawnedWindArrows.Num() == 0)
		{
			CurrentWindArrow = Cast<AWindArrow>(SpawnActor(WindArrowPlayerComp.WindArrowClass, SpawnLocation, AimRot, NAME_None, true));
			CurrentWindArrow.MakeNetworked(this, SpawnedArrowCounter);
			CurrentWindArrow.Player = Player;
			SpawnedArrowCounter++;
			FinishSpawningActor(CurrentWindArrow);
		}
		else
		{
			CurrentWindArrow = SpawnedWindArrows[0];
			if(CurrentWindArrow.bActive)
				WindArrowPlayerComp.RecycleWindArrow(CurrentWindArrow);
			CurrentWindArrow.Activate();
			CurrentWindArrow.ActorLocation = SpawnLocation;
			CurrentWindArrow.ActorRotation = AimRot;
			SpawnedWindArrows.Empty();
		}

		CurrentWindArrow.AttachToComponent(Player.Mesh, n"RightHand", EAttachmentRule::KeepWorld);
		SpawnedWindArrows.Add(CurrentWindArrow);

		UWindArrowEventHandler::Trigger_OnStartDraw(CurrentWindArrow);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
		Player.UnblockCapabilities(WindJavelin::WindJavelinTag, this);
        IceBowPlayerComp.bIsFiringIceBow = false;
		IceBowPlayerComp.bIsChargingIceBow = false;
		IceBowPlayerComp.SetChargeFactor(0.0);

		if(!bLaunched)
		{
			UWindArrowEventHandler::Trigger_OnEndDraw(CurrentWindArrow);
			WindArrowPlayerComp.RecycleWindArrow(CurrentWindArrow);
		}
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		if(!bFullyCharged && IceBowPlayerComp.GetChargeFactor() == 1.0)
		{
			bFullyCharged = true;
			CrumbOnFullyCharged();
		}

		if(!bReleasedInput && !IsActioning(IceBow::ShotAction))
		{
			bReleasedInput = true;
			if(bFullyCharged)
			{
				FIceBowTargetData TargetData = IceBowPlayerComp.CalculateTargetData(EIceBowArrowType::Wind);
				UWindArrowEventHandler::Trigger_OnEndDraw(CurrentWindArrow);
				CrumbLaunch(IceBowPlayerComp.GetChargeFactor(), IceBowPlayerComp.GetArrowSpawnLocation(), TargetData.Velocity, TargetData.GetDirection());
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnFullyCharged()
	{
		UWindArrowEventHandler::Trigger_OnArrowFullyCharged(CurrentWindArrow);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbLaunch(float ChargeFactor, FVector OriginLocation, FVector Velocity, FVector Direction)
	{
		Launch(ChargeFactor, OriginLocation, Velocity, Direction);
		bLaunched = true;
	}

    UIceBowSettings GetBowSettings() const property
    {
        return IceBowPlayerComp.BowSettings;
    }

	void Launch(float ChargeFactor, FVector OriginLocation, FVector Velocity, FVector Direction)
	{
		CurrentWindArrow.DetachFromActor(EDetachmentRule::KeepWorld);
		CurrentWindArrow.ActorLocation = OriginLocation;
		CurrentWindArrow.ActorRotation = FRotator::MakeFromX(Direction);
		IceBowPlayerComp.SetChargeFactor(ChargeFactor);
        CurrentWindArrow.ChargeFactor = ChargeFactor;
        const float ArrowGravity = WindArrowPlayerComp.GetArrowGravity();

        CurrentWindArrow.Launch(Velocity, ArrowGravity, ProjectileProximityComp, WindArrowPlayerComp);

        // Trigger events
        FWindArrowLaunchEventData LaunchData;
        LaunchData.LaunchImpulse = Velocity;
        LaunchData.ChargeFactor = IceBowPlayerComp.GetChargeFactor();
		UIceBowEventHandler::Trigger_LaunchWindArrow(Player, LaunchData);
        UWindArrowEventHandler::Trigger_Launch(CurrentWindArrow, LaunchData);

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
}