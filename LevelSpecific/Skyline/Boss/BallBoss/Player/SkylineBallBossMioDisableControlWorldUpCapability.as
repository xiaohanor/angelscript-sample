/**
 * While following the Ball Boss, we want to use a relative WorldUp.
 * By default, the Players use the control synced WorldUp at all times for consistency,
 * but since the ball boss rotates a lot, this causes issues.
 */
class USkylineBallBossMioDisableControlWorldUpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	// Important to run after camera updates
	default TickGroup = EHazeTickGroup::LastDemotable;

	UPlayerMovementComponent MoveComp;
	UGravityBladeUserComponent BladeComp;
	UHazeCrumbSyncedActorPositionComponent SyncedActorPositionComp;

	UCameraUserComponent CameraUserComponent;
	UHazeCrumbSyncedRotatorComponent SyncedRelativeCameraDesiredRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		BladeComp = UGravityBladeUserComponent::Get(Player);
		SyncedActorPositionComp = UHazeCrumbSyncedActorPositionComponent::Get(Player);

		CameraUserComponent = UCameraUserComponent::Get(Player);

		SyncedRelativeCameraDesiredRotation = UHazeCrumbSyncedRotatorComponent::GetOrCreate(Player, n"BallBossMioSyncedCameraRotation");
		SyncedRelativeCameraDesiredRotation.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!ShouldDisableControlWorldUp())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!ShouldDisableControlWorldUp())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (!HasControl())
			SyncedActorPositionComp.ApplyMaintainControlWorldUp(false, this);

		Player.BlockCapabilities(CameraTags::CameraReplication, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (!HasControl())
			SyncedActorPositionComp.ClearMaintainControlWorldUp(this);

		Player.UnblockCapabilities(CameraTags::CameraReplication, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Manually sync camera relative to the player
		if (HasControl())
		{
			FRotator DesiredCameraRotation = CameraUserComponent.GetDesiredRotation();
			FRotator RelativeDesiredCameraRotation = Player.ActorRelativeTransform.InverseTransformRotation(DesiredCameraRotation);
			SyncedRelativeCameraDesiredRotation.SetValue(RelativeDesiredCameraRotation);
		}
		else
		{
			FRotator RelativeDesiredCameraRotation = SyncedRelativeCameraDesiredRotation.GetValue();
			FRotator DesiredCameraRotation = Player.ActorRelativeTransform.TransformRotation(RelativeDesiredCameraRotation);
			DesiredCameraRotation = CameraUserComponent.GetClampedWorldRotation(DesiredCameraRotation);
			CameraUserComponent.SetDesiredRotation(DesiredCameraRotation, this);
		}
	}

	bool ShouldDisableControlWorldUp() const
	{
		auto FollowComp = MoveComp.GetCurrentMovementAttachmentComponent();
		if(FollowComp != nullptr)
		{
			if(FollowComp.Owner.IsA(ASkylineBallBoss))
				return true;

			auto ParentActor = FollowComp.Owner.AttachParentActor;
			while(ParentActor != nullptr)
			{
				if(ParentActor.IsA(ASkylineBallBoss))
					return true;

				ParentActor = ParentActor.AttachParentActor;
			}
		}

		return false;
	}
};