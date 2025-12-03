class UCentipedeProjectileTargetingCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UPlayerCentipedeComponent CentipedeComponent;
	UPlayerTargetablesComponent TargetablesComponent;

	float StopTargetCooldown = 0.5;
	float StopTargetTimer = 0.01;
	bool bWasPassingProjectile = false;
	bool bIsStopping = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Player);
		TargetablesComponent = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Don't activate if player not regurgitating projectile
		if (!CentipedeComponent.bPassingProjectile)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (StopTargetTimer < 0.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StopTargetTimer = 1.0;
		CentipedeComponent.AutoTargetedComponent = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CentipedeComponent.ClearMovementFacingDirectionOverride(this);
		CentipedeComponent.bAutoTargeting = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!CentipedeComponent.bPassingProjectile && bWasPassingProjectile)
		{
			StopTargetTimer = StopTargetCooldown;
			bIsStopping = true;
		}
		if (bIsStopping)
			StopTargetTimer -= DeltaTime;

		bWasPassingProjectile = CentipedeComponent.bPassingProjectile;

		UCentipedeProjectileTargetableComponent TargetableComponent = TargetablesComponent.GetPrimaryTarget(UCentipedeProjectileTargetableComponent);
		if (TargetableComponent != nullptr)
			CentipedeComponent.AutoTargetedComponent = TargetableComponent;

		if (CentipedeComponent.AutoTargetedComponent == nullptr)
			return;
	
		// Debug::DrawDebugSphere(TargetableComponent.WorldLocation, 200, 10, Player.IsMio() ? FLinearColor::LucBlue : FLinearColor::Green, 3);

		FVector PlayerToTargetable = (CentipedeComponent.AutoTargetedComponent.WorldLocation - Player.ActorLocation).ConstrainToPlane(Player.MovementWorldUp);

		FVector NeckLocation = CentipedeComponent.GetNeckJointLocationForPlayer(Player.Player);
		FVector NeckHeadVector = (Player.ActorLocation - NeckLocation).GetSafeNormal().ConstrainToPlane(Player.MovementWorldUp);

		FVector FacingDirection = PlayerToTargetable.ConstrainToCone(NeckHeadVector, Math::DegreesToRadians(Centipede::MaxHeadAngle * 2.0));
		FacingDirection.Normalize();
		CentipedeComponent.bAutoTargeting = true;

		CentipedeComponent.ApplyMovementFacingDirectionOverride(FacingDirection, this);
	}
}