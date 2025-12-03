class UAdultDragonAtLandingSiteCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroupOrder = 3;
	default TickGroup = EHazeTickGroup::ActionMovement;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UAdultDragonLandingSiteComponent LandingSiteComp;
	UAdultDragonLandingSiteSettings Settings;
	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	UPlayerTargetablesComponent TargetablesComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LandingSiteComp = UAdultDragonLandingSiteComponent::GetOrCreate(Player);
		Settings = UAdultDragonLandingSiteSettings::GetSettings(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!LandingSiteComp.bAtLandingSite)
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!LandingSiteComp.bAtLandingSite)
			return true;

		if(MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplyCameraSettings(LandingSiteComp.CurrentLandingSite.CameraSettings, 1.5, this, SubPriority = 60); 
		Player.BlockCapabilities(n"AdultDragon", this);
		FTutorialPrompt Tutorial;
		Tutorial.Action = ActionNames::Interaction;
		Tutorial.Text = FText::FromString("Blow Horn"); //NSLOCTEXT("AdultDragon", "BlowLandingSiteHorn", "Blow Horn");
		Player.ShowTutorialPrompt(Tutorial, LandingSiteComp);

		FTutorialPrompt CancelTutorial;
		CancelTutorial.Action = ActionNames::Cancel;
		CancelTutorial.Text = FText::FromString("Fly Off"); //NSLOCTEXT("AdultDragon", "LeaveLandingSite", "Fly Off");
		Player.ShowTutorialPrompt(CancelTutorial, LandingSiteComp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this, 1.5);
		Player.UnblockCapabilities(n"AdultDragon", this);
		Player.RemoveTutorialPromptByInstigator(LandingSiteComp);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				Movement.InterpRotationTo(LandingSiteComp.CurrentLandingSite.ActorQuat, Settings.RotationInterpSpeed);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"");
		}
	}
}