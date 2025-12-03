asset JetskiGroundMovementSettings of UJetskiMovementSettings
{
    MaxSpeed = 3500;
    MaxSpeedWhileTurning = 3000;
};

class UJetskiGroundMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

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
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!MoveComp.IsOnWalkableGround())
			return false;

		if(Jetski.IsInWater())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!MoveComp.IsOnWalkableGround())
			return true;

		if(Jetski.IsInWater())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Jetski.SetMovementState(EJetskiMovementState::Ground);
		UJetskiEventHandler::Trigger_OnStartGroundMovement(Jetski);

		Jetski.ApplySettings(JetskiGroundMovementSettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UJetskiEventHandler::Trigger_OnStopGroundMovement(Jetski);

		Jetski.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(MoveData, MoveComp.GroundContact.Normal))
			return;

		if (HasControl())
		{
			Jetski.AccelerateUpTowards(FQuat::MakeFromZX(MoveComp.GroundContact.Normal, Jetski.ActorForwardVector), 0.5, DeltaTime, this);

			FVector Velocity = MoveComp.Velocity;
			Velocity = Jetski.SetNewForwardVelocity(Velocity, EJetskiUp::GroundNormal, DeltaTime);
			MoveData.AddVelocity(Velocity);

			MoveData.AddGravityAcceleration();
			
			Jetski.SteerJetski(MoveData, DeltaTime);

			MoveData.AddPendingImpulses();

			if(ShouldAllowAligningWithCeiling())
				MoveData.AllowAligningWithCeiling();
		}
		else
		{
			MoveData.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}

	bool ShouldAllowAligningWithCeiling() const
	{
		const float DistanceAlongSpline = Jetski.GetDistanceAlongSpline();
		TOptional<FAlongSplineComponentData> CustomAlignmentData = Jetski.JetskiSpline.Spline.FindPreviousComponentAlongSpline(UJetskiSplineAllowAligningWithCeilingComponent, false, DistanceAlongSpline);
		if(!CustomAlignmentData.IsSet())
			return false;

		auto CustomAlignmentComp = Cast<UJetskiSplineAllowAligningWithCeilingComponent>(CustomAlignmentData.Value.Component);
		return CustomAlignmentComp.bAllowAligningWithCeiling;
	}
};