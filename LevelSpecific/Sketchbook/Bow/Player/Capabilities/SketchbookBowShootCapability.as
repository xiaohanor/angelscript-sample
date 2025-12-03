struct FSketchbookBowShootOnActivateParams
{
    float ChargeFactor;
    FTraversalTrajectory LaunchTrajectory;
};

/**
 * 
 */
class USketchbookBowShootCapability : UHazePlayerCapability
{
    default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
   	default DebugCategory = Sketchbook::Bow::DebugCategory;

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 110; // After Charge
    
    default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(Sketchbook::Bow::SketchbookBow);

	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(BlockedWhileIn::Crouch);

	USketchbookBowPlayerComponent BowComp;

    int SpawnedArrowCounter = 0;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        BowComp = USketchbookBowPlayerComponent::Get(Player);

		FOnHazeActorSpawned OnSpawnedBind;
		//OnSpawnedBind.AddUFunction(this, n"OnSpawnedBySpawner");
		BowComp.SpawnPoolComponent.OnSpawnedBySpawner.Add(this, OnSpawnedBind);
    }

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		BowComp.SpawnPoolComponent.OnSpawnedBySpawner.Remove(this);
	}

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate(FSketchbookBowShootOnActivateParams& Params) const
    {
        if (!BowComp.IsAiming())
            return false;

        if(BowComp.GetChargeFactor() < BowComp.BowSettings.MinimumCharge)
            return false;

		if(IsActioning(Sketchbook::Bow::ShootAction))
            return false;

        FTraversalTrajectory LaunchTrajectory = BowComp.CalculateLaunchTrajectory();
        Params.ChargeFactor = BowComp.GetChargeFactor();
        Params.LaunchTrajectory = LaunchTrajectory;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
		if (ActiveDuration >= BowComp.BowSettings.ShootAnimDuration)
			return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FSketchbookBowShootOnActivateParams Params)
    {
        // Spawn and launch arrow
        FRotator AimRot = FRotator::MakeFromX(Params.LaunchTrajectory.LaunchVelocity.GetSafeNormal());
		if(HasControl())
		{
             			FHazeActorSpawnParameters SpawnParams;
			SpawnParams.Location = BowComp.GetArrowSpawnLocation();
			SpawnParams.Rotation = AimRot;
			SpawnParams.Spawner = this;
			ASketchbookArrow Arrow = Cast<ASketchbookArrow>(BowComp.SpawnPoolComponent.SpawnControl(SpawnParams));
			CrumbLaunch(Arrow, Params);
		}

        // Camera shake
        if(BowComp.BowSettings.LaunchCameraShake != nullptr)
            Player.PlayCameraShake(BowComp.BowSettings.LaunchCameraShake, this, BowComp.GetChargeFactor());

        // Force Feedback
        if(BowComp.BowSettings.LaunchForceFeedback != nullptr)
            Player.PlayForceFeedback(BowComp.BowSettings.LaunchForceFeedback, false, false, this, BowComp.GetChargeFactor() * 0.1);
        
        // Reset
        BowComp.SetChargeFactor(0.0);
        BowComp.bIsFiringBow = true;

		Player.Mesh.SetAnimTrigger(n"RefreshPose");
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
		//Player.UnblockCapabilities(WindJavelin::WindJavelinTag, this);
        
        BowComp.bIsFiringBow = false;
    }

	UFUNCTION(CrumbFunction)
	void CrumbLaunch(ASketchbookArrow Arrow, FSketchbookBowShootOnActivateParams Params)
	{
		Arrow.SetActorControlSide(Player);

		if(BowComp.bUseFire)
		{
			ASketchbookArrowFire Fire = SpawnActor(BowComp.ArrowFireClass);
			Fire.AttachToArrow(Arrow);
		}

		BowComp.SetChargeFactor(Params.ChargeFactor);
		Arrow.ChargeFactor = Params.ChargeFactor;
		const float ArrowGravity = BowComp.GetArrowGravity();
		Arrow.Launch(Player, Params.LaunchTrajectory.LaunchVelocity, ArrowGravity, BowComp);

		// Trigger events
        FSketchbookArrowLaunchEventData LaunchData;
        LaunchData.LaunchImpulse = Params.LaunchTrajectory.LaunchVelocity;
        LaunchData.ChargeFactor = BowComp.GetChargeFactor();
		USketchbookBowPlayerEventHandler::Trigger_LaunchArrow(Player, LaunchData);
        USketchbookArrowEventHandler::Trigger_Launch(Arrow, LaunchData);
    }
}