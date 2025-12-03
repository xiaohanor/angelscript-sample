
class UPlayerGravityWellLaunchCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::GravityWell);
	default CapabilityTags.Add(PlayerWallRunTags::WallRunMovement);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 19;
	default TickGroupSubPlacement = 5;

	default DebugCategory = n"Movement";

	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;	

	UPlayerGravityWellComponent GravityWellComp;
	AGravityWell LaunchGravityWell;
	//FVector LaunchDirection;
	//EGravityWellLaunchDeactivationMode LaunchDeactivationMode;
	//float LaunchDuration;

	FVector CameraDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
		GravityWellComp = UPlayerGravityWellComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (ActiveGravityWell == nullptr)
			return false;

		if (!ActiveGravityWell.bEnabled)
			return false;

		float ToTarget = ActiveGravityWell.ExitTargetDistanceAlongSpline - GravityWellComp.DistanceAlongSpline;
		if (ActiveSpline.IsClosedLoop() && Math::Abs(ToTarget) > ActiveSpline.SplineLength / 2.0)
				ToTarget -= ActiveSpline.SplineLength * Math::Sign(ToTarget);

		if (!Math::IsNearlyZero(ToTarget, 1.0))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.HasAnyValidBlockingContacts())
			return true;

		if(LaunchGravityWell == nullptr)
			return true;

		if(ActiveGravityWell != nullptr && ActiveGravityWell != LaunchGravityWell)
			return true;

		if(LaunchGravityWell.LaunchDeactivateIfOutsideWell && !LaunchGravityWell.IsWorldLocationInsideWell(Player.ActorCenterLocation))
			return true;

		if(LaunchGravityWell.LaunchDeactivateAfterDuration >= 0 && ActiveDuration >= LaunchGravityWell.LaunchDeactivateAfterDuration)
			return true;

		if(LaunchGravityWell.LaunchDeactivateOnFalling && MoveComp.VerticalSpeed < 0.0)
			return true;

		if(LaunchGravityWell.LaunchDeactivateOnImpacts && MoveComp.HasAnyValidBlockingContacts())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::GravityWell, this);

		GravityWellComp.CurrentState = EPlayerGravityWellState::Movement;

		ActiveGravityWell.ApplySettings(Player, this);
		LaunchGravityWell = ActiveGravityWell;
		GravityWellComp.ForceClearGravityWell();
		GravityWellComp.bIsLaunching = true;
		GravityWellComp.GravityWellMovementDirection = FVector::ZeroVector;

		Player.SetActorVelocity(LaunchDirection * GravityWellComp.Settings.LaunchSpeed);

		CameraDirection = LaunchDirection.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		if (CameraDirection.IsNearlyZero())
			CameraDirection = Player.ActorForwardVector;	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::GravityWell, this);
		GravityWellComp.bIsLaunching = false;
		LaunchGravityWell = nullptr;
		
		Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if (MoveComp.PrepareMove(Movement))
		{
			Movement.AddOwnerVerticalVelocity();
			Movement.AddOwnerHorizontalVelocity();
			Movement.AddVelocity(-MoveComp.WorldUp * GravityWellComp.Settings.LaunchGravity * DeltaTime);
			
			FRotator TargetRotation = FRotator::MakeFromXZ(CameraDirection, MoveComp.WorldUp);
			Movement.SetRotation(Math::RInterpTo(Player.ActorRotation, TargetRotation, DeltaTime, 10.0));

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"GravityWell");
		}
	}

	AGravityWell GetActiveGravityWell() const property
	{
		return GravityWellComp.ActiveGravityWell;
	}

	UHazeSplineComponent GetActiveSpline() const property
	{
		return GravityWellComp.ActiveGravityWell.Spline;
	}

	FVector GetLaunchDirection() const property
	{
		return LaunchGravityWell.ExitDirection.WorldRotation.ForwardVector;
	}
	
}