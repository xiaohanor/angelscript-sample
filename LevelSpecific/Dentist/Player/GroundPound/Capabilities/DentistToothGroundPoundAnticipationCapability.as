struct FDentistToothGroundPoundAnticipationDeactivateParams
{
	bool bFinished = false;
};

class UDentistToothGroundPoundAnticipationCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Dentist::Tags::GroundPound);
	default CapabilityTags.Add(Dentist::Tags::CancelOnRagdoll);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 80;

	UDentistToothPlayerComponent PlayerComp;
	UDentistToothGroundPoundComponent GroundPoundComp;

	UPlayerMovementComponent MoveComp;
	UDentistToothMovementData MoveData;

	FVector StartWorldLocation;
	FQuat TargetRotation;

	FVector StartRelativeHorizontalLocation = FVector::ZeroVector;
	FVector StartRelativeVerticalLocation = FVector::ZeroVector;
	FVector TargetRelativeHorizontalOffset = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
		GroundPoundComp = UDentistToothGroundPoundComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		MoveData = MoveComp.SetupMovementData(UDentistToothMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(GroundPoundComp.DesiredState != EDentistToothGroundPoundState::Anticipation)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FDentistToothGroundPoundAnticipationDeactivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(GroundPoundComp.CurrentState != EDentistToothGroundPoundState::Anticipation)
			return true;

		if(GroundPoundComp.DesiredState != EDentistToothGroundPoundState::Anticipation)
			return true;

		if(ActiveDuration > GroundPoundComp.Settings.AnticipationDuration)
		{
			Params.bFinished = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GroundPoundComp.CurrentState = EDentistToothGroundPoundState::Anticipation;

		StartWorldLocation = Player.ActorLocation;
		TargetRotation = FQuat::MakeFromZX(FVector::UpVector, Player.ActorForwardVector);

		if(GroundPoundComp.AutoAimTarget != nullptr)
		{
			// If we are auto aiming, make the start location relative to the auto aim target
			FVector StartRelativeLocation = GroundPoundComp.AutoAimTarget.WorldTransform.InverseTransformPositionNoScale(StartWorldLocation);
			StartRelativeHorizontalLocation = StartRelativeLocation.VectorPlaneProject(MoveComp.WorldUp);
			StartRelativeVerticalLocation = StartRelativeLocation - StartRelativeHorizontalLocation;
			TargetRelativeHorizontalOffset = StartRelativeHorizontalLocation.GetClampedToMaxSize(GroundPoundComp.AutoAimTarget.MoveToRadius);
		}

		UDentistToothEventHandler::Trigger_OnStartGroundPoundAnticipation(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FDentistToothGroundPoundAnticipationDeactivateParams Params)
	{
		if(Params.bFinished)
			GroundPoundComp.DesiredState = EDentistToothGroundPoundState::Drop;

		UDentistToothEventHandler::Trigger_OnStopGroundPoundAnticipation(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(MoveData))
			return;

		const float Alpha = Math::Saturate(ActiveDuration / GroundPoundComp.Settings.AnticipationDuration);

		if (HasControl())
		{
			FVector TargetLocation;

			if(GroundPoundComp.AutoAimTarget == nullptr)
				TargetLocation = GetTargetLocationWorld(Alpha);
			else
				TargetLocation = GetTargetLocationRelative(Alpha);

			FVector Delta = TargetLocation - Player.ActorLocation;
			MoveData.AddDelta(Delta);
			MoveData.SetRotation(TargetRotation);
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMoveAndRequestLocomotion(MoveData, Dentist::Feature);

		const float AngleAlpha = GroundPoundComp.Settings.AnticipationAngleAlphaCurve.GetFloatValue(Alpha);
		FQuat SpinRotation = FQuat(FVector::RightVector, Math::DegreesToRadians(AngleAlpha * 180));
		SpinRotation = Player.ActorTransform.TransformRotation(SpinRotation);

		if(Dentist::GroundPound::bApplyRotation)
			PlayerComp.SetMeshWorldRotation(SpinRotation, this, GroundPoundComp.Settings.AnticipationOffsetResetDuration, DeltaTime);
	}

	FVector GetTargetLocationWorld(float Alpha) const
	{
		const float Height = GroundPoundComp.Settings.AnticipationHeightAlphaCurve.GetFloatValue(Alpha) * GroundPoundComp.Settings.AnticipationHeight;
		return StartWorldLocation + FVector(0, 0, Height);
	}

	FVector GetTargetLocationRelative(float Alpha)
	{
		const float Height = GroundPoundComp.Settings.AnticipationHeightAlphaCurve.GetFloatValue(Alpha) * GroundPoundComp.Settings.AnticipationHeight;

		const FVector RelativeVerticalLocation = StartRelativeVerticalLocation + (FVector(0, 0, Height));

		const float HorizontalAlpha = Math::EaseInOut(0, 1, Alpha, 1.5);
		const FVector RelativeHorizontalLocation = Math::Lerp(StartRelativeHorizontalLocation, TargetRelativeHorizontalOffset, HorizontalAlpha);
		const FVector RelativeLocation = RelativeHorizontalLocation + RelativeVerticalLocation;

		return GroundPoundComp.AutoAimTarget.WorldTransform.TransformPositionNoScale(RelativeLocation);
	}
};