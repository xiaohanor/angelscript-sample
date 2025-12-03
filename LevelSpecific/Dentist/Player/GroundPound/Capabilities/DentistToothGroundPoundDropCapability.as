struct FDentistToothGroundPoundDropDeactivateParams
{
	bool bFinished = false;
	FHitResult GroundImpact;
};

class UDentistToothGroundPoundDropCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	//default CapabilityTags.Add(Dentist::Tags::GroundPound);
	default CapabilityTags.Add(Dentist::Tags::CancelOnRagdoll);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;

	UDentistToothPlayerComponent PlayerComp;
	UDentistToothGroundPoundComponent GroundPoundComp;
	UDentistToothMovementSettings MovementSettings;

	UPlayerMovementComponent MoveComp;
	UDentistToothMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
		GroundPoundComp = UDentistToothGroundPoundComponent::Get(Player);
		MovementSettings = UDentistToothMovementSettings::GetSettings(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		MoveData = MoveComp.SetupMovementData(UDentistToothMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(GroundPoundComp.DesiredState != EDentistToothGroundPoundState::Drop)
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FDentistToothGroundPoundDropDeactivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(GroundPoundComp.CurrentState != EDentistToothGroundPoundState::Drop)
			return true;

		if(GroundPoundComp.DesiredState != EDentistToothGroundPoundState::Drop)
			return true;

		if(MoveComp.HasImpactedGround())
		{
			Params.bFinished = true;
			Params.GroundImpact = MoveComp.AllGroundImpacts[0];
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GroundPoundComp.CurrentState = EDentistToothGroundPoundState::Drop;

		UDentistToothEventHandler::Trigger_OnStartGroundPoundDrop(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FDentistToothGroundPoundDropDeactivateParams Params)
	{
		if(Params.bFinished)
			GroundPoundComp.DesiredState = EDentistToothGroundPoundState::Recover;

		UDentistToothEventHandler::Trigger_OnStopGroundPoundDrop(Player);

		if(Params.GroundImpact.IsValidBlockingHit())
			OnGroundPoundHit(Params.GroundImpact);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(MoveData))
			return;

		if (HasControl())
		{
			FVector VerticalVelocity = MoveComp.VerticalVelocity;
			FVector TargetVelocity = FVector::DownVector * GroundPoundComp.Settings.DropSpeed;
			VerticalVelocity = Math::VInterpConstantTo(VerticalVelocity, TargetVelocity, DeltaTime, GroundPoundComp.Settings.DropAcceleration);
			MoveData.AddVerticalVelocity(VerticalVelocity);

			//Movement.SetRotation(FQuat(FVector::UpVector, 10 * DeltaTime) * Player.ActorQuat);
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMoveAndRequestLocomotion(MoveData, Dentist::Feature);

		FQuat SpinRotation = FQuat(FVector::RightVector, Math::DegreesToRadians(180));
		SpinRotation = Player.ActorTransform.TransformRotation(SpinRotation);

		if(Dentist::GroundPound::bApplyRotation)
			PlayerComp.SetMeshWorldRotation(SpinRotation, this, -1, DeltaTime);
	}

	void OnGroundPoundHit(FHitResult Impact)
	{
		auto MovementResponseComp = UDentistToothMovementResponseComponent::Get(Impact.Actor);

		FDentistGroundPoundOnGroundHit EventData;
		EventData.ImpactLocation = Impact.ImpactPoint;
		EventData.Normal = Impact.Normal;
		EventData.MovementResponseComp = MovementResponseComp;
		UDentistToothEventHandler::Trigger_OnGroundPoundImpact(Player, EventData);

		Player.PlayForceFeedback(PlayerComp.ForceFeedbackGroundPound, false, false, this);
		Player.PlayCameraShake(PlayerComp.GroundPoundShake, this, 0.75);

		float BounceImpulse = GroundPoundComp.Settings.BounceImpulse;
		FVector BounceNormal = FVector::UpVector;
		bool bAllowHorizontalMovement = true;

		if(MovementResponseComp != nullptr)
		{
			if(MovementResponseComp.ShouldBounceFromImpact(EDentistToothBounceResponseType::GroundPound))
			{
				BounceImpulse = MovementResponseComp.GroundPoundBounceImpulse;
				BounceNormal = MovementResponseComp.GetBounceNormalForImpactType(Impact, EDentistToothBounceResponseType::GroundPound);
				bAllowHorizontalMovement = !MovementResponseComp.bGroundPoundRemoveHorizontalVelocity;
				MovementResponseComp.OnBouncedOn.Broadcast(Player, EDentistToothBounceResponseType::GroundPound, Impact);
			}

			MovementResponseComp.OnGroundPoundedOn.Broadcast(Player, Impact);
		}

		Bounce(BounceNormal * BounceImpulse, bAllowHorizontalMovement);
	}

	void Bounce(FVector BounceImpulse, bool bAllowHorizontalMovement)
	{
		FVector Impulse = BounceImpulse;

		if(bAllowHorizontalMovement)
		{
			FVector DesiredMoveSpeed = MoveComp.MovementInput * MovementSettings.GroundMaxSpeed * GroundPoundComp.Settings.BounceHorizontalFactor;
			Impulse += DesiredMoveSpeed;
		}

		Player.AddMovementImpulse(Impulse);
	}
};