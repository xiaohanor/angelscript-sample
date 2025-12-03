class UTundraPlayerTreeGuardianRangedGrappleKickbackCapability : UHazePlayerCapability
{
	// This is a copy of the tree guardians movement capability with some modifications such as no rotation code.

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 80;

	default CapabilityTags.Add(TundraRangedInteractionTags::RangedInteractionInteraction);
	default CapabilityTags.Add(CapabilityTags::Movement);

	UPlayerMovementComponent MoveComp;
	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;
	UTundraPlayerTreeGuardianComponent TreeGuardianComp;
	USteppingMovementData Movement;
	UTundraPlayerTreeGuardianSettings Settings;

	const float MaxDuration = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		Settings = UTundraPlayerTreeGuardianSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!TreeGuardianComp.bInKickback)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(MoveComp.HasGroundContact())
			return true;

		if(ActiveDuration >= MaxDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TreeGuardianComp.bInKickback = false;
		MoveComp.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				//FVector MovementInput = MoveComp.MovementInput;

				// if(MoveComp.HasGroundImpact())
				// 	Movement.AddHorizontalVelocity(MovementInput * Settings.GroundMovementAcceleration * DeltaTime);
				// else
				// 	Movement.AddHorizontalVelocity(MovementInput * Settings.AirMovementAcceleration * DeltaTime);

				ApplyFriction(DeltaTime);
				Movement.AddGravityAcceleration();
				Movement.AddOwnerVelocity();
				Movement.AddPendingImpulses();
			}
			else
			{
				if(MoveComp.HasGroundContact())
					Movement.ApplyCrumbSyncedGroundMovement();
				else
					Movement.ApplyCrumbSyncedAirMovement();
			}

			if(!MoveComp.HasGroundContact())
				Movement.RequestFallingForThisFrame();

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"TreeGuardianGrapple");
		}
	}

	void ApplyFriction(float DeltaTime)
	{
		float FrictionValue = MoveComp.HasGroundContact() ? Settings.HorizontalGroundFriction : Settings.HorizontalAirFriction;
		Movement.AddHorizontalVelocity(-MoveComp.HorizontalVelocity * (FrictionValue * DeltaTime));
	}
}