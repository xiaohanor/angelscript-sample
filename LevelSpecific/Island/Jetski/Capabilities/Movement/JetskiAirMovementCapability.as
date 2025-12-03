asset JetskiAirSettings of UJetskiSettings
{
	SlowMaxSteeringAmount = 70;
	FastMaxSteeringAmount = 30;
};

asset JetskiAirMovementSettings of UJetskiMovementSettings
{
    MaxSpeed = 3500;
    MaxSpeedWhileTurning = 1500;
    Acceleration = 1000;
    Deceleration = 200;
};

struct FJetskiAirMovementActivateParams
{
	EJetskiMovementState PreviousMovementState;
};

class UJetskiAirMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 130;

	AJetski Jetski;
	UJetskiMovementComponent MoveComp;
	UJetskiMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Jetski = Cast<AJetski>(Owner);
		MoveComp = Jetski.MoveComp;
		MoveData = MoveComp.SetupJetskiMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FJetskiAirMovementActivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		Params.PreviousMovementState = Jetski.GetMovementState();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FJetskiAirMovementActivateParams Params)
	{
		Jetski.SetMovementState(EJetskiMovementState::Air);

		if(Params.PreviousMovementState != EJetskiMovementState::Air)
			UJetskiEventHandler::Trigger_OnStartAirMovement(Jetski);

		if(Params.PreviousMovementState == EJetskiMovementState::Underwater)
			Jetski.bHasJumpedFromUnderwater = true;

		Jetski.ApplySettings(JetskiAirSettings, this);
		Jetski.ApplySettings(JetskiAirMovementSettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(Jetski.GetMovementState() != EJetskiMovementState::Air)
			UJetskiEventHandler::Trigger_OnStopAirMovement(Jetski);

			Jetski.bHasJumpedFromUnderwater = false;

		Jetski.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData, Jetski.ActorUpVector))
			return;

		if(HasControl())
		{
			FVector Velocity = Jetski.SetNewForwardVelocity(MoveComp.Velocity, EJetskiUp::Global, DeltaTime);
			MoveData.AddVelocity(Velocity);

			if(Velocity.Size() > 100)
			{
				FVector LookInDir;
				if(Velocity.VectorPlaneProject(FVector::UpVector).Size() < 100)
					LookInDir = Jetski.ActorForwardVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
				else
					LookInDir = MoveComp.Velocity.GetSafeNormal();

				FVector ForwardDir = MoveComp.HorizontalVelocity.GetSafeNormal();
				LookInDir = Math::Lerp(LookInDir, ForwardDir, 0.5);
				Jetski.AccelerateUpTowards(FQuat::MakeFromXZ(LookInDir, FVector::UpVector), 2, DeltaTime, this);
			}
			else
			{
				Jetski.AccelerateUpTowards(FQuat::MakeFromZX(FVector::UpVector, Jetski.ActorForwardVector), 2, DeltaTime, this);
			}

			MoveData.AddGravityAcceleration();
			Jetski.SteerJetski(MoveData, DeltaTime);

			MoveData.AddPendingImpulses();
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}
}