struct FDentistSplitToothGroundLungeMovementDeactivateParams
{
	FVector LungeDir = FVector::ZeroVector;
};

class UDentistSplitToothGroundLungeMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(Dentist::SplitTooth::SplitToothTag);
	default CapabilityTags.Add(Dentist::Tags::BlockedWhileDash);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 80;

	UDentistSplitToothComponent SplitToothComp;
	UDentistToothDashComponent DashComp;

	UHazeMovementComponent MoveComp;
	UDentistToothMovementData Movement;

	FVector LungeDir = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplitToothComp = UDentistSplitToothComponent::Get(Owner);
		DashComp = UDentistToothDashComponent::Get(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupMovementData(UDentistToothMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SplitToothComp.bIsSplit)
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if(MoveComp.IsInAir())
			return false;

		if(MoveComp.MovementInput.IsNearlyZero())
			return false;

		if(DashComp != nullptr && DashComp.IsActive())
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FDentistSplitToothGroundLungeMovementDeactivateParams& Params) const
	{
		if(!SplitToothComp.bIsSplit)
			return true;

		if (MoveComp.HasMovedThisFrame())
			return true;

		if(MoveComp.IsInAir())
		{
			Params.LungeDir = LungeDir;
			return true;
		}

		if(ActiveDuration > SplitToothComp.Settings.LungePrepareDuration)
		{
			Params.LungeDir = LungeDir;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FDentistSplitToothGroundLungeMovementDeactivateParams Params)
	{
		if(!Params.LungeDir.IsNearlyZero())
		{
			const FVector Impulse = LungeDir * SplitToothComp.Settings.LungeHorizontalImpulse + FVector::UpVector * SplitToothComp.Settings.LungeVerticalImpulse;
			MoveComp.AddPendingImpulse(Impulse);
			
			FDentistSplitToothOnLungeEventData EventData;
			EventData.Impulse = Impulse;
			UDentistSplitToothEventHandler::Trigger_OnLunge(Owner, EventData);
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!IsActive() && DeactiveDuration > 0.2)
			LungeDir = FVector::ZeroVector;

		//Debug::DrawDebugArrow(Owner.ActorLocation, Owner.ActorLocation + LungeDir * 500, 10, Thickness = 10);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;

		if (HasControl())
		{
			const FVector Input = MoveComp.MovementInput;

			LungeDir = Math::VInterpTo(LungeDir, Input, DeltaTime, SplitToothComp.Settings.LungeDirInterpSpeed);

			Movement.AddOwnerVerticalVelocity();

			FVector HorizontalVelocity = MoveComp.GetHorizontalVelocity();
			HorizontalVelocity = Math::VInterpConstantTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, SplitToothComp.Settings.GroundDeceleration);
			Movement.AddHorizontalVelocity(HorizontalVelocity);

			Movement.AddGravityAcceleration();

			if(!Input.IsNearlyZero())
				Movement.InterpRotationTo(FQuat::MakeFromZX(FVector::UpVector, Input), SplitToothComp.Settings.GroundRotationSpeed);
		
			Movement.AddPendingImpulses();
		}
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMove(Movement);
	}
};