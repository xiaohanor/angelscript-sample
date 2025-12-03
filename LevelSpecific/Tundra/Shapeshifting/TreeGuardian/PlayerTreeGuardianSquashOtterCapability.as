class UPlayerTreeGuardianSquashOtterCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerMovementComponent MoveComp;
	UPlayerTreeGuardianStepComponent StepComp;
	UTundraPlayerShapeshiftingComponent MioShapeshiftComp;
	UTundraPlayerTreeGuardianComponent TreeGuardianComp;

	const float MinVelocity = 20;
	const float CollisionRadius = 30;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);
		MioShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Game::GetMio());
		StepComp = TreeGuardianComp.TreeGuardianActor.StepComponent;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MioShapeshiftComp.CurrentShapeType != ETundraShapeshiftShape::Small)
			return false;

		if(MoveComp.Velocity.Size() < MinVelocity)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MioShapeshiftComp.CurrentShapeType != ETundraShapeshiftShape::Small)
			return true;

		if(MoveComp.Velocity.Size() < MinVelocity)
			return true;

		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FName Socket = StepComp.bIsLeft ? n"LeftFoot" : n"RightFoot";

		if(Overlap::QueryShapeOverlap(
			MioShapeshiftComp.Player.CapsuleComponent.GetCollisionShape(), 
			MioShapeshiftComp.Player.CapsuleComponent.WorldTransform, 
			FCollisionShape::MakeSphere(CollisionRadius), 
			TreeGuardianComp.GetShapeMesh().GetSocketTransform(Socket))
			)
			{
				MioShapeshiftComp.Player.KillPlayer();
			}

	}
};