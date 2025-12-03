
class UPlayerWallRunLedgeTurnAroundCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::WallRun);
	default CapabilityTags.Add(PlayerWallRunTags::WallRunCamera);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 179;

	default DebugCategory = n"Movement";

	UPlayerWallRunComponent WallRunComp;
	UPlayerMovementComponent MoveComp;
	UCameraUserComponent CamUserComp;

	FAcceleratedInputInterruptedDesiredRotation AcceleratedDesiredRotation;
	default AcceleratedDesiredRotation.AcceleratedDuration = 0.5;
	default AcceleratedDesiredRotation.PostInputCooldown = 0.0;
	default AcceleratedDesiredRotation.PostCooldownInputScaleInterp = 1.5;

	FVector SpeedupDesiredDirection;
	FRotator SpeedupEndRotation;

	FVector SlowdownDesiredDirection;
	FRotator SlowdownEndRotation;

	/*
		TODO[AL]
		- Rework camera motion as this is a really temp version for UXR
			- Potentially  one smooth transition And/Or curve it and add potential camera shakes/impulses
	*/

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		WallRunComp = UPlayerWallRunComponent::GetOrCreate(Player);
		CamUserComp = UCameraUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WallRunComp.State== EPlayerWallRunState::WallRunLedgeTurnaround)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WallRunComp.State != EPlayerWallRunState::WallRunLedgeTurnaround)
			return true;

		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AcceleratedDesiredRotation.Activate(Player.GetCameraDesiredRotation());

		//Define our estimated forward direction upon speeding back up
		//Might want to recalculate this on tick to align with changes to ledge orientation
		SpeedupDesiredDirection = WallRunComp.LedgeTurnaroundData.InitiatedForwardDirection * -1;
		SpeedupEndRotation = FRotator::MakeFromX(SpeedupDesiredDirection);
		SpeedupEndRotation.Pitch -= 5.0;

		if(WallRunComp.CameraSettings != nullptr)
			Player.ApplyCameraSettings(WallRunComp.CameraSettings, 1.0, this, SubPriority = 27);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdatePivotOffset(DeltaTime);
		UpdateDesiredRotation(DeltaTime);
	}

	void UpdatePivotOffset(float DeltaTime)
	{
		FVector PivotOffset = FVector(0.0, 0.0, 65.0);

		//Offset the pivot out from the wall
		PivotOffset += WallRunComp.ActiveData.WallNormal * 100.0;
		UCameraSettings::GetSettings(Player).WorldPivotOffset.Apply(PivotOffset, this, 0.5, EHazeCameraPriority::Low);
	}

	void UpdateDesiredRotation(float DeltaTime)
	{
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::CameraDirection);

		FRotator NewDesired;

		if(WallRunComp.LedgeTurnaroundData.bSlowingDown)
		{
			//Assign our desired as facing the wall to focus on the player performing the turnaround
			FVector DirToWall = WallRunComp.ActiveData.GetWallNormal() * -1;

			SlowdownEndRotation = FRotator::MakeFromX(DirToWall);
			SlowdownEndRotation.Pitch -= 5.0;

			FRotator DesiredRotation = Math::RInterpConstantTo(CamUserComp.DesiredRotation, SlowdownEndRotation, DeltaTime, 800);
			NewDesired = AcceleratedDesiredRotation.Update(CamUserComp.DesiredRotation, DesiredRotation, Input, DeltaTime);
		}	
		else
		{
			//Assign our desired as facing camera towards travel direction along with speedup
			FRotator DesiredRotation = Math::RInterpConstantTo(CamUserComp.DesiredRotation, SpeedupEndRotation, DeltaTime, 800);
			NewDesired = AcceleratedDesiredRotation.Update(CamUserComp.DesiredRotation, DesiredRotation, Input, DeltaTime);
		}

		CamUserComp.SetDesiredRotation(NewDesired, this);
	}
}