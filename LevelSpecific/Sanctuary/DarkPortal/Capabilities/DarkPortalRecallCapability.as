class UDarkPortalRecallCapability : UHazeCapability
{
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortalRecall);

	default TickGroup = EHazeTickGroup::Movement;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADarkPortalActor Portal;
	AHazePlayerCharacter Player;
	UDarkPortalUserComponent UserComp;

	float CurrentSpeed;
	float CurrentDistance;
	FHazeRuntimeSpline MovementSpline;

	FVector StartLocation;
	FVector StartForward;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Portal = Cast<ADarkPortalActor>(Owner);
		Player = Portal.Player;
		UserComp = UDarkPortalUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Portal.IsRecalling())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Portal.IsRecalling())
			return true;

		if ((CurrentDistance >= MovementSpline.Length) && (ActiveDuration > 0.2))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FDarkPortalRecallEventData RecallParams;
		RecallParams.PortalTransform = Portal.ActorTransform;
		UDarkPortalEventHandler::Trigger_Recalled(Portal, RecallParams);

		Portal.Recall(); // Ensure this is done on remote

		Portal.PushAndReleaseAll();
		Portal.DetachPortal();

		Portal.ActorTransform = Player.Mesh.GetSocketTransform(DarkPortal::Absorb::AttachSocket);

		StartLocation = Portal.ActorLocation;
		StartForward = Portal.ActorForwardVector;
		MovementSpline = CalculateMovementSpline();

		CurrentSpeed = 0.0;
		CurrentDistance = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Portal.AttachPortal(Player.Mesh.GetSocketTransform(DarkPortal::Absorb::AttachSocket), Player.Mesh, DarkPortal::Absorb::AttachSocket);
		Portal.SetState(EDarkPortalState::Absorb);
		UDarkPortalEventHandler::Trigger_Absorbed(Portal);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			MovementSpline = CalculateMovementSpline();

			CurrentSpeed = Math::FInterpConstantTo(CurrentSpeed, DarkPortal::Recall::MaximumSpeed, DeltaTime, DarkPortal::Recall::Acceleration);
			CurrentDistance = Math::Clamp(CurrentDistance + CurrentSpeed * DeltaTime, 0.0, MovementSpline.Length);
			CurrentSpeed -= CurrentSpeed * DarkPortal::Recall::Drag * DeltaTime;

			FVector Location = MovementSpline.GetLocationAtDistance(CurrentDistance);
			FVector DeltaMovement = (Location - Portal.ActorLocation);

			FQuat Rotation = Portal.ActorQuat;
			if (!DeltaMovement.IsNearlyZero())
			{
				Rotation = FQuat::Slerp(Rotation,
					FQuat::MakeFromXZ(Player.MovementWorldUp, DeltaMovement.GetSafeNormal()),
					10.0 * DeltaTime);
			}

			Portal.SetActorLocationAndRotation(
				Location,
				Rotation
			);
		}
		else
		{
			auto Position = Portal.SyncedPosition.Position;
			Portal.SetActorLocationAndRotation(
				Position.WorldLocation,
				Position.WorldRotation
			);
		}
	}

	FHazeRuntimeSpline CalculateMovementSpline()
	{
		auto Spline = FHazeRuntimeSpline();
		Spline.AddPoint(StartLocation);
		Spline.AddPoint(Player.Mesh.GetSocketLocation(DarkPortal::Absorb::AttachSocket));
		Spline.SetCustomEnterTangentPoint(StartLocation - StartForward);
		return Spline;
	}
}