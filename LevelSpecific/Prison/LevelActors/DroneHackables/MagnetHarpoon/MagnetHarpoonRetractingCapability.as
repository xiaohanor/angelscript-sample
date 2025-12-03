struct FMagnetHarpoonRetractingDeactivateParams
{
	bool bReachedEnd;
}

class UMagnetHarpoonRetractingCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	AMagnetHarpoon MagnetHarpoon;
	AHazePlayerCharacter Player;
	TArray<UPrimitiveComponent> HarpoonPrimitives;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MagnetHarpoon = Cast<AMagnetHarpoon>(Owner);
		Player = Drone::GetSwarmDronePlayer();
		MagnetHarpoon.HarpoonRoot.GetChildrenComponentsByClass(UPrimitiveComponent, true, HarpoonPrimitives);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MagnetHarpoon.State != EMagnetHarpoonState::Retracting)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FMagnetHarpoonRetractingDeactivateParams& Params) const
	{
		if(MagnetHarpoon.State != EMagnetHarpoonState::Retracting)
			return true;

		if (MagnetHarpoon.HarpoonRoot.GetWorldLocation().Equals(MagnetHarpoon.DefaultHarpoonWorldLocation))
		{
			Params.bReachedEnd = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MagnetHarpoon.AttachData.Invalidate();

		// Disable collision on the harpoon while it retracts to prevent chaos
		for(auto HarpoonPrimitive : HarpoonPrimitives)
		{
			HarpoonPrimitive.AddComponentCollisionBlocker(this);
		}

		// Stupid sometimes, comment for now
		// Revert cable length
		// MagnetHarpoon.CableComp.CableLength = 100.0;

		UMagnetHarpoonEventHandler::Trigger_OnRetract(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FMagnetHarpoonRetractingDeactivateParams Params)
	{
		if(Params.bReachedEnd)
		{
			MagnetHarpoon.State = EMagnetHarpoonState::Aim;
			MagnetHarpoon.HarpoonRoot.SetAbsolute(false, false);
			MagnetHarpoon.HarpoonRoot.SetRelativeLocationAndRotation(MagnetHarpoon.DefaultHarpoonRelativeLocation, FRotator::ZeroRotator);

			UMagnetHarpoonEventHandler::Trigger_OnFullyRetracted(Owner);
		}

		for(auto HarpoonPrimitive : HarpoonPrimitives)
		{
			HarpoonPrimitive.RemoveComponentCollisionBlocker(this);
		}

		// Lazily do a super quick burst (ideally use an asset.. but mnah)
		Player.SetFrameForceFeedback(1, 1, 1, 1);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Start slow retraction to allow magnet player to escape
		float Multiplier = Math::Pow(Math::Abs(ActiveDuration / 0.15), 1.2);
		const FVector Loc = Math::VInterpConstantTo(MagnetHarpoon.HarpoonRoot.WorldLocation, MagnetHarpoon.DefaultHarpoonWorldLocation, DeltaTime, MagnetHarpoon.LaunchSpeed * Multiplier);
		MagnetHarpoon.HarpoonRoot.SetRelativeLocation(Loc);

		FVector ForwardVector = (MagnetHarpoon.HarpoonRoot.WorldLocation - MagnetHarpoon.RotationRoot.WorldLocation).GetSafeNormal();
		FQuat TargetRotation = FQuat::MakeFromX(ForwardVector);
		FQuat Rotation = Math::QInterpTo(MagnetHarpoon.HarpoonRoot.ComponentQuat, TargetRotation, DeltaTime, 12);
		MagnetHarpoon.HarpoonRoot.SetRelativeRotation(Rotation);

		// FF juice
		FHazeFrameForceFeedback ForceFeedback;
		ForceFeedback.RightMotor = 0.1;
		ForceFeedback.RightTrigger = 0.1;
		Player.SetFrameForceFeedback(ForceFeedback);
	}
};