
class UPlayerPolevaultAnticipationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleMovement);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 11;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerPolevaultComponent PolevaultComp;

    float Duration = .6;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		PolevaultComp = UPlayerPolevaultComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

        if (!PolevaultComp.bAnticipate)
            return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (ActiveDuration >= Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplyCameraSettings(PolevaultComp.CamSettingAnticipation, 1, this, SubPriority = 52);

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
        PolevaultComp.bAnticipate = false;
        PolevaultComp.bPolevault = true;
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{		

			}
			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"", this);
		}

	}



};

