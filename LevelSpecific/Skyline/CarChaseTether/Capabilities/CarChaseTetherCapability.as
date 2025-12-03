class UCarChaseTetherCapability : UHazePlayerCapability
{
	/*
		**** CAR CHASE TETHER NOTE ****
		This is a quick prototype version based on swing logic,
		this is only to get an idea for the gameplay as this is LITERALLY a rehash of swing per Pod 4's request
	*/

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::Swing);
	default CapabilityTags.Add(n"PlayerToCarTether");
	default CapabilityTags.Add(n"PlayerToCarTetherMovement");

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 18;
	default TickGroupSubPlacement = 2;

	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;

	UCarChaseTetherPlayerComponent TetherComp;
	UPlayerTargetablesComponent TargetablesComp;

	UCameraUserComponent CameraUser;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();

		CameraUser = UCameraUserComponent::Get(Owner);

		TetherComp = UCarChaseTetherPlayerComponent::GetOrCreate(Player);
		TargetablesComp = UPlayerTargetablesComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCarChaseTetherActivationParams& ActivationParams) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!WasActionStarted(ActionNames::Grapple))
			return false;

		UTargetableComponent Targetable = TargetablesComp.GetPrimaryTarget(UContextualMovesTargetableComponent);
		UCarChaseTetherPointComponent TargetableTetherPointComp = Cast<UCarChaseTetherPointComponent>(Targetable);

		if(TargetableTetherPointComp == nullptr)
			return false;
		
		ActivationParams.TetherPoint = TargetableTetherPointComp;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!TetherComp.HasActivatedTetherPoint())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCarChaseTetherActivationParams ActivationParams)
	{
		//temp using swing blocking
		Player.BlockCapabilities(BlockedWhileIn::Swing, this);
		//prevent world up snapping of camera
		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);

		ActivationParams.TetherPoint.ApplySettings(Player, this);
		ActivationParams.TetherPoint.Disable(this);

		Player.OverrideGravityDirection(-ActivationParams.TetherPoint.Owner.ActorForwardVector, this);

		TetherComp.ActivateTether(ActivationParams.TetherPoint);
		TetherComp.Data.AcceleratedTetherLength.SnapTo(TetherComp.TetherPointToPlayer.Size());

		FRotator ViewRotation = TetherComp.Data.ActiveTetherPoint.Owner.ActorForwardVector.Rotation();
		CameraUser.SetYawAxis(TetherComp.Data.ActiveTetherPoint.Owner.ActorUpVector, this);
		ViewRotation.Roll = 0.0;
		CameraUser.SetDesiredRotation(ViewRotation, this);

		Player.ApplyCameraSettings(TetherComp.Data.ActiveTetherPoint.CameraSettings, 1.0, this, SubPriority = 60);

		Player.PlaySlotAnimation(Animation = TetherComp.TempAnimation, bLoop = true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Swing, this);
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);

		Player.ClearGravityDirectionOverride(this);

		Player.ClearSettingsByInstigator(this);
		TetherComp.Data.ActiveTetherPoint.Enable(this);
		TetherComp.DeactivateTether();
	
		Player.StopSlotAnimationByAsset(TetherComp.TempAnimation);
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//Draw Temp Tether
		FLinearColor TetherColor = FLinearColor(0.15, 0.10, 0.10);
		Debug::DrawDebugLine(TetherComp.TetherPointLocation, Player.Mesh.GetSocketLocation(n"LeftAttach"), TetherColor, 5.0,);		
		Debug::DrawDebugLine(Player.Mesh.GetSocketLocation(n"LeftAttach"), Player.Mesh.GetSocketLocation(n"RightAttach"), TetherColor, 5.0);		
		Debug::DrawDebugLine(Player.Mesh.GetSocketLocation(n"RightAttach"), Player.Mesh.GetSocketLocation(n"Hips"), TetherColor, 5.0);
	}
}

struct FCarChaseTetherActivationParams
{
	UCarChaseTetherPointComponent TetherPoint;
}