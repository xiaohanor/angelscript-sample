
class UIslandOverseerChargeAttackBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;
	default CapabilityTags.Add(n"Single");
	default CapabilityTags.Add(n"Attack");

	UBasicAICharacterMovementComponent MoveComp;

	AAIIslandOverseerEye Eye;
	TArray<AHazePlayerCharacter> HitPlayers;
	FVector PreviousLocation;
	AHazePlayerCharacter Target;
	FVector MoveDirection;
	FVector StartLocation;
	bool bCheckHeight;
	bool bStoppedTelegraph;
	bool bWallBounced;
	bool bGroundBounced;
	int Bounces;
	int MaxBounces = 3;
	const float MaxDuration = 6;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Eye = Cast<AAIIslandOverseerEye>(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!Eye.EyesManagerComp.CanAttack(Eye, EIslandOverseerEyeAttack::Charge))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > MaxDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Eye.EyesManagerComp.ClaimAttack(Eye);
		PreviousLocation = Eye.ActorLocation;
		Eye.Speed = 4500;
		Target = Eye.bBlue ? Game::Mio : Game::Zoe;
		StartLocation = Owner.ActorLocation;
		bCheckHeight = false;
		bStoppedTelegraph = false;
		UIslandOverseerEyeEventHandler::Trigger_OnChargeTelegraphStart(Owner);
		Bounces = 0;
		HitPlayers.Empty();
		bGroundBounced = false;
		bWallBounced = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if(Eye.EyesManagerComp != nullptr)
			Eye.EyesManagerComp.ReleaseAttack(Eye);
		Owner.ClearSettingsByInstigator(this);
		UIslandOverseerEyeEventHandler::Trigger_OnChargeTelegraphStop(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < 3)
		{
			MoveDirection = (Target.ActorLocation - Owner.ActorLocation).ConstrainToPlane(Eye.Boss.ActorForwardVector).GetSafeNormal();
			DestinationComp.RotateInDirection(MoveDirection);
			UBasicAIMovementSettings::SetTurnDuration(Owner, 0, this);
			return;
		}

		if(!bStoppedTelegraph)
		{
			bStoppedTelegraph = true;
			UIslandOverseerEyeEventHandler::Trigger_OnChargeTelegraphStop(Owner);
		}

		FVector Forward = (Eye.ActorLocation - PreviousLocation).ConstrainToPlane(Eye.Boss.ActorForwardVector);
		DestinationComp.RotateInDirection(Forward);
		PreviousLocation = Eye.ActorLocation;

		Eye.AccSpeed.AccelerateTo(Eye.Speed, 2, DeltaTime);
		DestinationComp.MoveTowardsIgnorePathfinding(Owner.ActorLocation + MoveDirection * 100, Eye.Speed);

		// Stop charging when we are above our starting location
		if(bCheckHeight && Owner.ActorLocation.Z > StartLocation.Z)
			DeactivateBehaviour();

		FVector Normal = FVector::ZeroVector;
		FVector Impact = FVector::ZeroVector;

		bool bHasBounce = false;

		if(MoveComp.HasWallContact() && !bWallBounced)
		{
			bWallBounced = true;
			bHasBounce = true;

			UIslandOverseerEyeEventHandler::Trigger_OnWallContact(Owner);
			if(Eye.Boss.ActorRightVector.DotProduct(Eye.ActorLocation - Eye.Boss.ActorLocation) > 0)
				Normal = -Eye.Boss.ActorRightVector;
			else
				Normal = Eye.Boss.ActorRightVector;
			Impact = MoveComp.WallContact.ImpactPoint;
		} 

		if(MoveComp.HasGroundContact() && !bGroundBounced)
		{
			bGroundBounced = true;
			bHasBounce = true;
			Normal = (Normal + Eye.Boss.ActorUpVector).GetSafeNormal();
			Impact = (Impact + MoveComp.GroundContact.ImpactPoint) / 2;
		}

		if(bHasBounce)
			SetDirection(Normal, Impact);
		else
		{
			bGroundBounced = false;
			bWallBounced = false;
		}


		if(MoveComp.HasCeilingContact())
			DeactivateBehaviour();

		DamagePlayers();
	}

	private void SetDirection(FVector Normal, FVector ImpactLocation)
	{
		Bounces++;
		if(Bounces > MaxBounces-1)
		{
			DeactivateBehaviour();
			return;
		}

		bCheckHeight = true;
		FVector u = Normal * Eye.MeshOffsetComponent.ForwardVector.DotProduct(Normal);
		FVector w = Eye.MeshOffsetComponent.ForwardVector - u;
		MoveDirection = (w - u).ConstrainToPlane(Eye.Boss.ActorForwardVector).GetSafeNormal();
		
		FIslandOverseerEyeEventHandlerOnChargeBounceData Data;
		Data.ImpactLocation = ImpactLocation;
		Data.ImpactNormal = Normal;
		UIslandOverseerEyeEventHandler::Trigger_OnChargeBounce(Owner, Data);
	}

	private void DamagePlayers()
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(HitPlayers.Contains(Player))
				continue;

			if(Player.ActorCenterLocation.PointPlaneProject(Eye.ActorLocation, Eye.Boss.ActorForwardVector).IsWithinDist(Owner.ActorLocation, 75))
			{
				HitPlayers.Add(Player);
				Player.DamagePlayerHealth(0.5, DamageEffect = Eye.DamageEffect, DeathEffect = Eye.DeathEffect);
				FKnockdown Knock;
				Knock.Duration = 1;
				Knock.Move = (Player.ActorLocation - Eye.ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector) * 500;
				Player.ApplyKnockdown(Knock);
			}
		}
	}
}