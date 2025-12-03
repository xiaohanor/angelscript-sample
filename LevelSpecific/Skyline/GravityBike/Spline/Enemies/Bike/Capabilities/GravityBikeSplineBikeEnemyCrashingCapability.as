struct FGravityBikeSplineBikeEnemyCrashingActivateParams
{
	bool bIsGrounded = false;
};

class UGravityBikeSplineBikeEnemyCrashingCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 80;

	AGravityBikeSplineBikeEnemy BikeEnemy;
	UHazeMovementComponent MoveComp;
	USimpleMovementData MoveData;

	UGravityBikeSplineEnemyMovementComponent SplineMoveComp;
	UGravityBikeSplineEnemyHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BikeEnemy = Cast<AGravityBikeSplineBikeEnemy>(Owner);
		MoveComp = BikeEnemy.MoveComp;
		MoveData = MoveComp.SetupSimpleMovementData();

		SplineMoveComp = BikeEnemy.SplineMoveComp;
		HealthComp = UGravityBikeSplineEnemyHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeSplineBikeEnemyCrashingActivateParams& Params) const
	{
		if(BikeEnemy.State != EGravityBikeSplineBikeEnemyState::Crashing)
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!HealthComp.IsDead())
			return false;

		if(HealthComp.bExplode)
			return false;

		Params.bIsGrounded = BikeEnemy.MoveComp.IsOnAnyGround();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!HealthComp.IsDead())
			return true;

		if(ActiveDuration > BikeEnemy.AfterCrashDelay)
			return true;

		if(MoveComp.HasImpactedWall() || MoveComp.HasImpactedCeiling())
			return true;

		if(ActiveDuration > 0.1 && MoveComp.HasImpactedGround())
			return true;

		if(HealthComp.bExplode)
			return true;

		if(ActiveDuration > 1.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeSplineBikeEnemyCrashingActivateParams Params)
	{
		BikeEnemy.ThrowTargetComp.Disable(this);

		UGravityBikeSplineBikeEnemyEventHandler::Trigger_OnStartCrashing(BikeEnemy);

		if(Params.bIsGrounded)
		{
			// If we are grounded, apply impulse up
			const FVector Impulse = BikeEnemy.MovementWorldUp * BikeEnemy.CrashVerticalImpulse;
			BikeEnemy.AddMovementImpulse(Impulse);
		}

		BikeEnemy.BlockCapabilities(GravityBikeSpline::Enemy::EnemyFireTag, this);
		
		BikeEnemy.MovementState = EGravityBikeSplineBikeEnemyMovementState::None;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HealthComp.bExplode = true;
		BikeEnemy.State = EGravityBikeSplineBikeEnemyState::Default;
		BikeEnemy.ThrowTargetComp.Enable(this);

		BikeEnemy.UnblockCapabilities(GravityBikeSpline::Enemy::EnemyFireTag, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TickMovement(DeltaTime);

		float CrashTimeAlpha = Math::Saturate(ActiveDuration / BikeEnemy.AfterCrashDelay);
		float PitchSpeed = Math::Lerp(BikeEnemy.CrashPitchSpeed, BikeEnemy.CrashPitchSpeed * 0.2, Math::Pow(CrashTimeAlpha, 2));
		BikeEnemy.MeshPivot.SetRelativeRotation(FQuat(FVector::RightVector, PitchSpeed * DeltaTime) * BikeEnemy.MeshPivot.RelativeRotation.Quaternion());
	}

	void TickMovement(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		MoveData.AddOwnerVelocity();

		const FVector Gravity = FVector::DownVector * BikeEnemy.CrashGravity;
		MoveData.AddAcceleration(Gravity);

		MoveData.AddPendingImpulses();

		MoveComp.ApplyMove(MoveData);
	}
};