


/** 
 * A target we can shoot at.
*/
class UScifiCopsGunShootTargetableComponent : UCopsGunAutoAimTargetComponentBase
{
	default TargetableCategory = n"CopsGunShootTarget";

	default bUseVariableAutoAimMaxAngle = true;
	default AutoAimMaxAngleMinDistance = 12;
	default AutoAimMaxAngleAtMaxDistance = 8;

	// If true, we will auto aim at this target while holding the weapons in our hands
	UPROPERTY(EditAnywhere, Category = "CopsGun")
	bool bCanTargetWhileHandShooting = true;

	// If true, the weapon can auto aim at this wile flying trough the air
	UPROPERTY(EditAnywhere, Category = "CopsGun")
	bool bCanTargetWhileFreeFlying = true;

	// If true, the weapon will auto aim at this target while attached to the environment
	UPROPERTY(EditAnywhere, Category = "CopsGun")
	bool bCanTargetWhileEnvironmentAttached = true;

	/** This one is called when the weapon is handheld. Like a normal target */
	protected bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if(!bCanTargetWhileHandShooting)
		{
			Query.Result.Score = 0;
			return false;
		}

		if(!Super::CheckTargetable(Query))
			return false;

		return true;
	}

	/** This one is used when the weapons has been thrown. We can then skip a lot of requirement */
	bool CheckWeaponTargetable(UScifiPlayerCopsGunManagerComponent Manager, float CurrentBestScore, float& OutScore) const
	{
		// Bonus score for each weapon
		float WeaponTargetScoreMultiplier = 1;		
		if(Manager.CurrentShootAtTarget == this)
		{
			// We keep the current target longer
			WeaponTargetScoreMultiplier += 1.0;
		}

		// Turret scoring
		if(Manager.bTurretIsActive)
		{
			if(!bCanTargetWhileEnvironmentAttached)
			{
				return false;
			}
		}
		else
		{
			if(!bCanTargetWhileFreeFlying)
			{
				return false;
			}
		}

		const FVector WeaponPosition = Manager.GetWeaponsMedianLocation();
		const float Distance = WeaponPosition.Distance(GetWorldLocation());

		if (Distance < MinimumDistance)
			return false;
		if (Distance > MaximumDistance)
			return false;
		
		
		const FVector TargetDirection = (GetWorldLocation() - WeaponPosition).GetSafeNormal();
		const float AngularBend = Math::RadiansToDegrees(Manager.GetWeaponsAimDirection().AngularDistanceForNormals(TargetDirection));

		const float MaxAngle = 90;
		if (AngularBend > MaxAngle)
		{
			return false;
		}

		// Score the distance based on how much we have to bend the aim
		const float FinalDistanceWeight = 0.8;
		
		OutScore = (1.0 - (Distance / MaximumDistance)) * FinalDistanceWeight;
		OutScore += (1.0 - (AngularBend / MaxAngle)) * (1.0 - FinalDistanceWeight);

		// Apply bonus to score
		OutScore *= ScoreMultiplier;
		OutScore *= WeaponTargetScoreMultiplier;

		if(OutScore <= CurrentBestScore)
			return false;

		if(!CheckWeaponFreeSight(Manager, WeaponPosition, TargetDirection))
			return false;

		return true;
	}	

	private bool CheckWeaponFreeSight(UScifiPlayerCopsGunManagerComponent Manager, FVector Origin, FVector AimDirection) const
	{
		// Make sure we get the player so we have the same move ignores as the player has
		FHazeTraceSettings Trace = Trace::InitFromPlayer(Manager.PlayerOwner, n"TargetableOcclusion");
		Trace.TraceWithChannel(ECollisionChannel::PlayerAiming);
		Trace.UseLine();

		Trace.IgnoreActor(Owner);
		Trace.IgnoreActor(Manager.GetLeftWeapon().GetAttachedToActor());	
		Trace.IgnoreActor(Manager.GetRightWeapon().GetAttachedToActor());	

		FVector StartLocation = Origin;
		StartLocation += AimDirection * 30;

		FVector TargetPosition = WorldLocation;
		TargetPosition -= AimDirection * 20;

		FHitResult Hit = Trace.QueryTraceSingle(
			StartLocation,
			TargetPosition,
		);

		return !Hit.bBlockingHit;
	}
}

/** 
 * The a target we can throw the weapons at
 * Place it under a 'UScifiCopsGunShootTargetableComponent' to link the shooting to that one
*/
class UScifiCopsGunThrowTargetableComponent : UCopsGunAutoAimTargetComponentBase 
{
	default TargetableCategory = n"CopsGunThrowTarget";

	default bUseVariableAutoAimMaxAngle = true;
	default AutoAimMaxAngleMinDistance = 12;
	default AutoAimMaxAngleAtMaxDistance = 8;
	default MaximumDistance = 3000;
	default MinimumDistance = 300;

	UPROPERTY(EditAnywhere, Category = "CopsGun")
	EScifiPlayerCopsGunAttachTargetType Type = EScifiPlayerCopsGunAttachTargetType::Weapon;

	// If true, this will override the default settings
	UPROPERTY(EditAnywhere, Category = "CopsGun")
	bool bUseCustomStayAtTargetTime = false;

	// >= 0; the duration is used. < 0; you have to press recall
	UPROPERTY(EditAnywhere, Category = "CopsGun", meta = (EditCondition = "bUseCustomStayAtTargetTime"))
	float CustomStayAtTargetTime = 0;

	// How the guns will behave once they have reached the target
	UPROPERTY(EditAnywhere, Category = "CopsGun")
	EScifiPlayerCopsGunTargetMovementType ReachedTargetMovementType = EScifiPlayerCopsGunTargetMovementType::None;

	private bool bIsLinkedWithShootAtTarget = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		bIsLinkedWithShootAtTarget = GetAttachParent().IsA(UScifiCopsGunShootTargetableComponent);
	}

	protected bool CheckTargetable(FTargetableQuery& Query) const override
	{	
		if(!Super::CheckTargetable(Query))
			return false;

		if(Query.Result.Score <= 0)
			return false;
		
		// Add some stickyness to the throw target
		auto Manager = UScifiPlayerCopsGunManagerComponent::Get(Query.Player);
		if(Manager.CurrentThrowTargetPoint == this)
		{
			Query.Result.Score += 2;
		}

		return true;
	}

	UScifiCopsGunShootTargetableComponent GetLinkedShootAtTarget() const
	{
		if(!bIsLinkedWithShootAtTarget)
			return nullptr;

		return Cast<UScifiCopsGunShootTargetableComponent>(GetAttachParent());
	}
}

/**
 * A throwable target that requires an angle to be valid
 */
class UScifiCopsGunThrowAngleTargetableComponent : UScifiCopsGunThrowTargetableComponent
{
	default bUseVariableAutoAimMaxAngle = false;
	default AutoAimMaxAngle = 90;
}


/**
 * The base class for copsgun targets
 */
UCLASS(Abstract)
class UCopsGunAutoAimTargetComponentBase : UAutoAimTargetComponent
{
	default TargetableCategory = n"InvalidCategory";

	private bool CheckPrimaryOcclusion(FTargetableQuery& Query, FVector TargetPoint) const override
	{
		// If our score is already 0, we don't need to do any extra traces
		if (Query.Result.Score <= 0.0 && !Query.Result.bVisible)
			return false;

		// Make sure we get the player so we have the same move ignores as the player has
		FHazeTraceSettings Trace = Trace::InitFromPlayer(Query.Player, n"TargetableOcclusion");
		Trace.TraceWithChannel(ECollisionChannel::PlayerAiming);
		Trace.UseLine();

		Trace.IgnoreActor(Query.Component.Owner);
		for (auto Player : Game::Players)
			Trace.IgnoreActor(Player);

		FVector TargetPosition = TargetPoint;
		TargetPosition -= (TargetPosition - Query.AimRay.Origin).GetSafeNormal() * 20;

		auto Hits = Trace.QueryTraceMulti(
			Query.AimRay.Origin,
			TargetPosition,
		);

		for(auto Hit : Hits)
		{
			if (Hit.bBlockingHit)
			{
				auto EneryWall = Cast<AScifiShieldBusterEnergyWall>(Hit.Actor);
				if(EneryWall != nullptr && EneryWall.CurrentWallCutter != nullptr)
				{
					FVector HolePosition = EneryWall.CurrentWallCutter.ActorLocation;
					float HoleSize = EneryWall.CurrentWallCutter.CurrentSize;
					if(Hit.ImpactPoint.DistSquared(HolePosition) <= Math::Square(HoleSize))
						continue;
				}

				Query.Result.Score = 0.0;
				Query.Result.bPossibleTarget = false;
				Query.Result.bVisible = false;
				return false;
			}
		}

		return true;
	}
}

/**
 * OBS!! Only used internally to aim at walls
 */
class UScifiCopsGunInternalEnvironmentThrowTargetableComponent : UScifiCopsGunThrowTargetableComponent 
{
	default bUseVariableAutoAimMaxAngle = false;
	default MaximumDistance = 100000;
	default MinimumDistance = 0;
	default bUseCustomStayAtTargetTime = true;
	default CustomStayAtTargetTime = -1;
	default ScoreMultiplier = 0.25;
	default bIsAutoAimEnabled = false;

	float CalculateAutoAimMaxAngle(float CurrentDistance) const override
	{
		return 180;
	}

	bool CheckPrimaryOcclusion(FTargetableQuery& Query, FVector TargetLocation) const override
	{
		return true;
	}

}