class UPirateShipTelescopePlayerCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UPirateShipTelescopePlayerComponent PlayerComp;
	UCameraUserComponent CameraUserComp;



	bool bMeshesHidden = false;
	FRotator WorldRotation;

	FHazeAcceleratedFloat AccZoomAlpha;
	FHazeAcceleratedFloat AccFocalDistance;
	UPirateTelescopeWidget Widget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UPirateShipTelescopePlayerComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!PlayerComp.bIsUsingTelescope)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!PlayerComp.bIsUsingTelescope)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(!PlayerComp.bHasFocusedOnTarget || Pirate::Telescope::bAlwaysFocusOnTarget)
		{
			auto Target = Pirate::GetTelescopeTarget();
			FVector ToTargetDir = (Target.ActorLocation - PlayerComp.Telescope.Camera.CameraComp.WorldLocation).GetSafeNormal();

			FRotator InitialRotation = FRotator::MakeFromXZ(ToTargetDir, FVector::UpVector);
			UpdateCameraRotation(InitialRotation);

			PlayerComp.bHasFocusedOnTarget = true;
		}
		else
		{
			UpdateCameraRotation(CameraUserComp.GetDesiredRotation());
		}

		AccFocalDistance.SnapTo(GetFocalDistance());
		PlayerComp.Telescope.BP_OnPlayerStartUsingTelescope(Player, AccFocalDistance.Value);

		Player.ActivateCamera(PlayerComp.Telescope.Camera.CameraComp, Pirate::Telescope::BlendInTime, this);
		UCameraSettings::GetSettings(Player).FOV.Apply(Pirate::Telescope::RegularFOV, this, Priority = EHazeCameraPriority::High);
		UCameraSettings::GetSettings(Player).FOV.Apply(Pirate::Telescope::ZoomFOV, this, Priority = EHazeCameraPriority::VeryHigh);
		UCameraSettings::GetSettings(Player).FOV.SetManualFraction(0, this);

		Widget = Player.AddWidget(PlayerComp.WidgetClass, EHazeWidgetLayer::Gameplay);
		Widget.SetWidgetZOrderInLayer(-1000);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CameraUserComp.SetDesiredRotation(PlayerComp.Telescope.Camera.CameraComp.WorldRotation, this);
		Player.DeactivateCameraByInstigator(this, Pirate::Telescope::BlendInTime);
		UCameraSettings::GetSettings(Player).FOV.Clear(this);
		SetMeshesHidden(false);

		AccZoomAlpha.SnapTo(0);
		PlayerComp.Telescope.Camera.CameraComp.SetFieldOfView(Pirate::Telescope::RegularFOV);
		Widget.StartFadingOut();
		Widget = nullptr;

		PlayerComp.Telescope.BP_OnPlayerStopUsingTelescope(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bMeshesHidden && ActiveDuration > Pirate::Telescope::BlendInTime)
		{
			SetMeshesHidden(true);
		}

		PlayerComp.Telescope.Camera.UpdateCameraLocation();
		
		const FVector2D CameraInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);

		const float CameraSensitivity = 1;
		const float Yaw = CameraInput.X * CameraSensitivity;
		const float Pitch = CameraInput.Y * CameraSensitivity;

		FRotator CurrentRotation = WorldRotation;

		const float MaxPitch = 80;
		CurrentRotation.Yaw += Yaw;
		CurrentRotation.Pitch = Math::Clamp(CurrentRotation.Pitch + Pitch, -MaxPitch, MaxPitch);

		CurrentRotation.Normalize();

		UpdateCameraRotation(CurrentRotation);

		if(IsActioning(ActionNames::PrimaryLevelAbility) || IsActioning(ActionNames::SecondaryLevelAbility))
			AccZoomAlpha.AccelerateTo(1, 1, DeltaTime);
		else
			AccZoomAlpha.AccelerateTo(0, 1, DeltaTime);

		UCameraSettings::GetSettings(Player).FOV.SetManualFraction(AccZoomAlpha.Value, this);

		AccFocalDistance.AccelerateTo(GetFocalDistance(), 0.5, DeltaTime);
		PlayerComp.Telescope.BP_UpdateFocalDistance(Player, AccFocalDistance.Value);

		if(Player.IsPlayerDead() || Player.IsPlayerRespawning())
			PlayerComp.Telescope.InteractionComp.KickAnyPlayerOutOfInteraction();
	}

	float GetFocalDistance() const
	{
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.UseSphereShape(200);
		TraceSettings.IgnorePlayers();
		TraceSettings.IgnoreActor(Pirate::GetShip());

		const float MaxDistance = 100000;
		FVector Start = PlayerComp.Telescope.Camera.CameraComp.WorldLocation;
		FVector TraceDir = PlayerComp.Telescope.Camera.CameraComp.ForwardVector;
		FVector End = Start + (TraceDir * MaxDistance);
		FHitResult Hit = TraceSettings.QueryTraceSingle(Start, End);

		FPlane WaterPlane = FPlane(FVector(0, 0, Pirate::GetWaterPlaneHeight()), FVector::UpVector);
		FVector Intersection = WaterPlane.RayPlaneIntersection(Start, TraceDir);
		FVector ToIntersection = Intersection - Start;
		const float DistanceToWaterIntersection = ToIntersection.Size();
		bool bHasWaterIntersection = ToIntersection.DotProduct(TraceDir) > 0;

		float TraceDistance = 0;

		if(Hit.IsValidBlockingHit())
		{
			TraceDistance = Hit.Distance;
		}
		else
		{
			TraceDistance = MaxDistance;
		}

		if(bHasWaterIntersection)
			return Math::Min(TraceDistance, DistanceToWaterIntersection);
		else
			return TraceDistance;
	}

	void AddToSniperRotation(float InYaw, float InPitch)
	{
		check(HasControl());

	}

	void UpdateCameraRotation(FRotator Rotation)
	{
		WorldRotation = Rotation;
		PlayerComp.Telescope.Camera.CameraComp.SetWorldRotation(Rotation);
	}

	void SetMeshesHidden(bool bHide)
	{
		Player.Mesh.SetRenderedForPlayer(Player, !bHide);

		TArray<AActor> ActorsAttachedToPlayer;
		Player.GetAttachedActors(ActorsAttachedToPlayer);

		for(auto AttachedActor : ActorsAttachedToPlayer)
		{
			TArray<UPrimitiveComponent> Primitives;
			AttachedActor.GetComponentsByClass(Primitives);

			for(auto Primitive : Primitives)
			{
				Primitive.SetRenderedForPlayer(Player, !bHide);
			}
		}

		TArray<UPrimitiveComponent> TelescopePrimitives;
		PlayerComp.Telescope.GetComponentsByClass(TelescopePrimitives);

		for(auto Primitive : TelescopePrimitives)
		{
			Primitive.SetRenderedForPlayer(Player, !bHide);
		}
	}
};