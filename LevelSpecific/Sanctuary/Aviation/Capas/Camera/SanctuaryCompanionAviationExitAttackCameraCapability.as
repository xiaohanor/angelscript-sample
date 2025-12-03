class USanctuaryCompanionAviationExitAttackCameraCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	USanctuaryCompanionAviationPlayerComponent AviationComp;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ASanctuaryCompanionAviationPostAttackCamera ExitAttackCamera;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AviationComp.GetIsAviationActive())
			return false;

		if (!IsInHandledState())
			return false;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!AviationComp.GetIsAviationActive())
			return true;

		if (!IsInHandledState())
			return true;
		
		return false;
	}

	bool IsInHandledState() const
	{
		if (AviationComp.AviationState == EAviationState::TryExitAttack)
			return true;

		if (AviationComp.AviationState == EAviationState::Exit)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Find the nearest camera spline
		TListedActors<ASanctuaryCompanionAviationPostAttackCamera> AvailableCameraSplines;
		for (auto Camera : AvailableCameraSplines)
		{
			if (!Player.IsSelectedBy(Camera.Player))
				continue;
			
			ExitAttackCamera = Camera;
			ExitAttackCamera.SetActorLocation(Player.ActorLocation);
			ExitAttackCamera.SetActorRotation(FRotator::MakeFromXZ(GetLandingPointDirection(), FVector::UpVector));
			if (ExitAttackCamera != nullptr)
				Player.ActivateCamera(ExitAttackCamera, AviationComp.Settings.PostAttackCameraBlendInTime, this, EHazeCameraPriority::High);
			break;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (ExitAttackCamera != nullptr)
			Player.DeactivateCamera(ExitAttackCamera, AviationComp.Settings.PostAttackCameraBlendOutTime);
		ExitAttackCamera = nullptr;
	}

	private FVector GetLandingPointDirection()
	{
		const FSanctuaryCompanionAviationDestinationData& DestinationData = AviationComp.GetNextDestination();
		FVector Delta = DestinationData.GetLocation() - Player.ActorLocation;
		Delta.Z = 0.0;
		return Delta.GetSafeNormal();
	}
}