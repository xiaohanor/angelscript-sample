// FB TODO: This entire capability is a hack now that we have added supports for sockets as well!
class UMagnetDroneCameraActivateCameraCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDrone);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneCamera);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 101;

	UMagnetDroneAttachedComponent AttachedComp;

	UDroneMagneticSurfaceComponent ActiveSurfaceComp;
	UDroneMagneticSocketComponent ActiveSocketComp;
	UHazeCameraComponent ActiveCamera;
	float TimeWithoutActiveCamera = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!AttachedComp.IsAttached())
			return false;

		if(!AttachmentHasCamera())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveSurfaceComp == nullptr && ActiveSocketComp == nullptr)
			return true;

		if(ActiveCamera == nullptr)
			return true;

		if(ActiveSurfaceComp != nullptr)
		{
			if(!AttachmentHasCamera() && TimeWithoutActiveCamera > ActiveSurfaceComp.ActivateCameraWaitUntilDeactivateDuration)
				return true;
		}
		else if(ActiveSocketComp != nullptr)
		{
			if(!AttachmentHasCamera() && TimeWithoutActiveCamera > ActiveSocketComp.ActivateCameraWaitUntilDeactivateDuration)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TimeWithoutActiveCamera = 0;
		
		ActiveSurfaceComp = GetCurrentSurface();
		ActiveSocketComp = GetCurrentSocket();
		ActiveCamera = GetCurrentAttachmentCamera();

		if(ActiveSurfaceComp != nullptr)
		{
			Player.ActivateCamera(ActiveCamera, ActiveSurfaceComp.ActivateCameraBlendInTime, this, ActiveSurfaceComp.ActivateCameraPriority);
		}
		else if(ActiveSocketComp != nullptr)
		{
			Player.ActivateCamera(ActiveCamera, ActiveSocketComp.ActivateCameraBlendInTime, this, ActiveSocketComp.ActivateCameraPriority);
		}

		Player.BlockCapabilities(CapabilityTags::FindOtherPlayer, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(ActiveSurfaceComp != nullptr)
		{
			Player.DeactivateCameraByInstigator(this, ActiveSurfaceComp.ActivateCameraBlendOutTime);
		}
		else if(ActiveSocketComp != nullptr)
		{
			Player.DeactivateCameraByInstigator(this, ActiveSocketComp.ActivateCameraBlendOutTime);
		}
		else
		{
			Player.DeactivateCameraByInstigator(this, -1);
		}

		ActiveSurfaceComp = nullptr;
		ActiveSocketComp = nullptr;
		ActiveCamera = nullptr;

		Player.UnblockCapabilities(CapabilityTags::FindOtherPlayer, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!AttachmentHasCamera())
		{
			TimeWithoutActiveCamera += DeltaTime;
			return;
		}
		else
		{
			TimeWithoutActiveCamera = 0;

			if(ActiveSurfaceComp != nullptr)
			{
				UDroneMagneticSurfaceComponent CurrentSurfaceComp = GetCurrentSurface();
				if(CurrentSurfaceComp != ActiveSurfaceComp)
				{
					if(HasControl())
						CrumbChangeSurface(CurrentSurfaceComp);
				}
			}
			else if(ActiveSocketComp != nullptr)
			{
				UDroneMagneticSocketComponent CurrentSocketComp = GetCurrentSocket();
				if(CurrentSocketComp != ActiveSocketComp)
				{
					if(HasControl())
						CrumbChangeSocket(CurrentSocketComp);
				}
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbChangeSurface(UDroneMagneticSurfaceComponent NewCurrentSurfaceComp)
	{
		Player.DeactivateCameraByInstigator(this, ActiveSurfaceComp.ActivateCameraBlendOutTime);

		ActiveSurfaceComp = NewCurrentSurfaceComp;
		ActiveCamera = NewCurrentSurfaceComp.CameraComp;

		Player.ActivateCamera(ActiveCamera, NewCurrentSurfaceComp.ActivateCameraBlendInTime, this, NewCurrentSurfaceComp.ActivateCameraPriority);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbChangeSocket(UDroneMagneticSocketComponent NewCurrentSocketComp)
	{
		Player.DeactivateCameraByInstigator(this, ActiveSocketComp.ActivateCameraBlendOutTime);

		ActiveSocketComp = NewCurrentSocketComp;
		ActiveCamera = UHazeCameraComponent::Get(NewCurrentSocketComp.CameraActor);

		Player.ActivateCamera(ActiveCamera, NewCurrentSocketComp.ActivateCameraBlendInTime, this, NewCurrentSocketComp.ActivateCameraPriority);
	}

	UDroneMagneticSocketComponent GetCurrentSocket() const
	{
		if(!AttachedComp.IsAttachedToSocket())
			return nullptr;

		return AttachedComp.AttachedData.GetSocketComp();
	}

	UDroneMagneticSurfaceComponent GetCurrentSurface() const
	{
		if(!AttachedComp.IsAttachedToSurface())
			return nullptr;

		return AttachedComp.AttachedData.GetSurfaceComp();
	}

	UHazeCameraComponent GetCurrentAttachmentCamera() const
	{
		auto SurfaceComp = GetCurrentSurface();
		if(SurfaceComp != nullptr)
		{
			if(SurfaceComp.CameraType != EMagneticSurfaceComponentCameraType::ActivateCamera)
				return nullptr;

			return SurfaceComp.CameraComp;
		}

		auto SocketComp = GetCurrentSocket();
		if(SocketComp != nullptr)
		{
			if(SocketComp.bUseAutomaticWallCamera)
				return nullptr;

			if(SocketComp.CameraActor == nullptr)
				return nullptr;

			return UHazeCameraComponent::Get(SocketComp.CameraActor);
		}

		return nullptr;
	}

	bool AttachmentHasCamera() const
	{
		return GetCurrentAttachmentCamera() != nullptr;
	}
}	