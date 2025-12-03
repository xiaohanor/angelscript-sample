struct FMagnetHarpoonAttachedActivateParams
{
	AActor HitActor;
	FVector AttachLocation;
}

class UMagnetHarpoonAttachedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AMagnetHarpoon MagnetHarpoon;
	AHazePlayerCharacter Player;

	UMagnetHarpoonGunResponseComponent CurrentResponseComp;

	FHazeAcceleratedQuat AcceleratedRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MagnetHarpoon = Cast<AMagnetHarpoon>(Owner);
		Player = Drone::GetSwarmDronePlayer();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMagnetHarpoonAttachedActivateParams& Params) const
	{
		if (!MagnetHarpoon.HijackTargetableComp.IsHijacked())
			return false;

		if(MagnetHarpoon.State != EMagnetHarpoonState::Launched)
			return false;

		if(!MagnetHarpoon.AttachData.CanAttach())
			return false;

		Params.HitActor = MagnetHarpoon.AttachData.Actor;
		Params.AttachLocation = MagnetHarpoon.AttachData.ImpactPoint;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration < 0.2)
			return false;

		if (!MagnetHarpoon.HijackTargetableComp.IsHijacked())
			return true;

		if(MagnetHarpoon.State != EMagnetHarpoonState::Attached)
			return true;

		if (!IsActioning(ActionNames::WeaponFire))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMagnetHarpoonAttachedActivateParams Params)
	{
		MagnetHarpoon.State = EMagnetHarpoonState::Attached;

		MagnetHarpoon.HarpoonRoot.SetWorldLocation(Params.AttachLocation);

		if (Params.HitActor != nullptr)
		{
			auto ResponseComp = UMagnetHarpoonGunResponseComponent::Get(Params.HitActor);
			if (ResponseComp != nullptr)
			{
				CurrentResponseComp = ResponseComp;
				ResponseComp.OnHarpoonAttached.Broadcast();
			}
		}

		AcceleratedRotation.SnapTo(MagnetHarpoon.HarpoonRoot.ComponentQuat);

		FMagnetHarpoonOnHitAttachEventData EventData;
		EventData.HitActor = Params.HitActor;
		EventData.AttachLocation = Params.AttachLocation;
		UMagnetHarpoonEventHandler::Trigger_OnHitAttach(Owner, EventData);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MagnetHarpoon.State = EMagnetHarpoonState::Retracting;

		MagnetHarpoon.AttachData.Invalidate();

		if (CurrentResponseComp != nullptr)
		{
			CurrentResponseComp.OnHarpoonDetached.Broadcast();
			CurrentResponseComp = nullptr;
		}

		UMagnetHarpoonEventHandler::Trigger_OnDetach(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Lerp rotation to follow normal
		FQuat TargetRotation = FQuat::MakeFromXZ(-MagnetHarpoon.AttachData.GetImpactNormal(), FVector::UpVector);
		AcceleratedRotation.SpringTo(TargetRotation, 2500, 0.0, DeltaTime * 0.8);
		MagnetHarpoon.HarpoonRoot.SetRelativeRotation(AcceleratedRotation.Value);
	}
};