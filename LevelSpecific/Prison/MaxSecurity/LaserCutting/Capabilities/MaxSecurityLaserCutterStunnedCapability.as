class UMaxSecurityLaserCutterStunnedCapability : URemoteHackableBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AMaxSecurityLaserCutter Cutter;
	float StunStruggleTime = 0.0;
	float RotationSpeed = 100.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		Cutter = Cast<AMaxSecurityLaserCutter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		if(Cutter.Stunners <= 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;

		if(Cutter.Stunners <= 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		Cutter.bStunned = true;
		Cutter.BP_Stunned();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Cutter.bStunned = false;
		Cutter.BP_Unstunned();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if(HasControl())
		{
			FVector2D Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
			
			FVector MoveInputXY = FVector(Input.Y, Input.X, 0);

			FVector Forward = Player.ViewRotation.ForwardVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
			FRotator Rotation = FRotator::MakeFromX(Forward);
			FVector CrosshairMove = Rotation.RotateVector(MoveInputXY) * RotationSpeed * DeltaTime;

			if (!Input.IsZero())
			{
				StunStruggleTime += DeltaTime;
				float Pitch = Math::Sin(StunStruggleTime * 8.0) * 0.05;
				float Roll = Math::Sin(StunStruggleTime * 12.0) * 0.15;
				Cutter.CutterRoot.SetRelativeRotation(FRotator(Cutter.StunRotation.Pitch + Pitch * CrosshairMove.X, Cutter.CutterRoot.RelativeRotation.Yaw, Cutter.StunRotation.Roll + Roll * CrosshairMove.Y));

				FMaxSecurityLaserCutterSyncedData SyncedData;
				Cutter.SyncComponent.GetCrumbValueStruct(SyncedData);
				SyncedData.RootRelativeLocation = Cutter.CutterRoot.RelativeLocation;
				SyncedData.RootWorldRotation = Cutter.CutterRoot.ComponentQuat;
				Cutter.SyncComponent.SetCrumbValueStruct(SyncedData);
			}
		}
		else
		{
			FMaxSecurityLaserCutterSyncedData SyncedData;
			Cutter.SyncComponent.GetCrumbValueStruct(SyncedData);
			Cutter.CutterRoot.SetRelativeLocation(SyncedData.RootRelativeLocation);
			Cutter.CutterRoot.SetWorldRotation(SyncedData.RootWorldRotation);
		}
	}
};