asset TeenDragonMovementSettingsDecimatorPlayerTrapOverride of UTeenDragonMovementSettings
{
   	MinimumSpeed = 100.0;
	MaximumSpeed = 150.0;
    SprintSpeed =  150.0;
    DashSpeed = 150.0;
    TurnMultiplier = 1.0;

	// Should not be necessary to override, but to be safe.
    AirHorizontalMinMoveSpeed = 100.0;
    AirHorizontalMaxMoveSpeed = 150.0;
}

class USummitDecimatorTopdownPlayerTrapCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(n"PlayerTrap");

	default TickGroup = EHazeTickGroup::BeforeMovement;
	
	UBasicAIHealthComponent HealthComp;
	ASummitDecimatorTopdownPlayerTrap Self;
	AAISummitDecimatorTopdown Decimator;

	FName PlayerCollisionProfileName;
	float TelegraphDuration = 2.05;

	bool bIsPlayerBlocked = false;
	bool bIsDestroyed = false;
	bool bHasTelegraphStopped = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{		
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		UTeenDragonTailAttackResponseComponent TailAttackResponseComp = UTeenDragonTailAttackResponseComponent::Get(Owner);
		TailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		UAcidResponseComponent AcidResponseComp = UAcidResponseComponent::Get(Owner);
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		Self = Cast<ASummitDecimatorTopdownPlayerTrap>(Owner);
		Self.BlockCapabilities(CapabilityTags::Collision, this);
		Self.Target = Game::Zoe;
		devCheck(Self.Decimator != nullptr, "Decimator ref is not set on player trap!");
		Decimator = Self.Decimator;
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if (!IsActive())
			return;

		if(Self.Target != Game::Mio)
			return;

		bIsDestroyed = true;
		USummitDecimatorTopdownPlayerTrapEffectsHandler::Trigger_OnCrystalSmashed(Owner);
		USummitDecimatorTopdownEffectsHandler::Trigger_OnTrapCrystalSmashed(Decimator);
		Self.SetActorHiddenInGame(true);
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		if (!IsActive())
			return;

		if(Self.Target != Game::Zoe)
			return;

		if(Self.MeltComp.GetMeltAlpha() < 0.9)
			return;

		if (!bIsDestroyed)
		{
			USummitDecimatorTopdownPlayerTrapEffectsHandler::Trigger_OnMelted(Owner);
			USummitDecimatorTopdownEffectsHandler::Trigger_OnTrapMelted(Decimator);
		}
		bIsDestroyed = true;
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (HealthComp.IsDead())
			return false;
		if (Self.Target.IsActorDisabled())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HealthComp.IsDead())
			return true;

		bool bIsTargetDead = UPlayerHealthComponent::Get(Self.Target).bIsDead;
		if (bIsTargetDead)
			return true;

		if (bIsDestroyed)
			return true;

		if (Self.DecimatorPhaseComp.CurrentPhase > 2)
			return true;

		return false;
	}

	bool bDisplacedOtherPlayer = false;
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Self.MetalMesh.SetHiddenInGame(true);
		Self.CrystalMesh.SetHiddenInGame(true);
		Self.SetActorHiddenInGame(false);
		USummitDecimatorTopdownPlayerTrapEffectsHandler::Trigger_OnTelegraphStarted(Owner, FSummitDecimatorTopdownPlayerTrapTelegraphParams(Self.Target));
		USummitDecimatorTopdownEffectsHandler::Trigger_OnTrapTelegraphStarted(Decimator, FSummitDecimatorTopdownPlayerTrapTelegraphParams(Self.Target));
		
		if (Self.Target == Game::Mio)
		{
			Self.OtherPlayer = Game::Zoe;		
		}
		else
		{
			Self.OtherPlayer = Game::Mio;			
		}

		Self.ProjectileMesh.SetHiddenInGame(false, true);
		PrevCurveLoc = FVector::ZeroVector;
		TargetLocation = Self.Target.ActorLocation;
		
		LandTangent = FVector::UpVector;		
		FVector LandDir = Self.LaunchVelocity;
		LandDir.Z *= -1.0;
		LandTangent = LandDir;
	}

	// Called on Control side
	UFUNCTION()
	void EnableTrappingControl()
	{
		// Owner.ActorLocation is not updated since last teleport call.
		Self.TeleportActor(Self.Target.ActorLocation, Self.GetActorRotation(), this);
		FVector ToOtherPlayer = (Self.OtherPlayer.ActorLocation - Owner.ActorLocation);
		bool bDoDisplaceOtherPlayer = ToOtherPlayer.Size2D() < 400;
		CrumbEnableTrapping(bDoDisplaceOtherPlayer);
	}

	UFUNCTION(CrumbFunction)
	void CrumbEnableTrapping(bool bDoDisplaceOtherPlayer)
	{
		Self.SetActorHiddenInGame(false);
		Self.ProjectileMesh.SetHiddenInGame(true, true);
		if (Self.Target == Game::Mio)
		{
			Self.OtherPlayer = Game::Zoe;
			Self.MetalMesh.SetHiddenInGame(true);
			Self.CrystalMesh.SetHiddenInGame(false);
			USummitDecimatorTopdownPlayerTrapEffectsHandler::Trigger_OnCrystalTrapped(Owner);
			USummitDecimatorTopdownEffectsHandler::Trigger_OnTrapCrystalTrapped(Decimator);
		}
		else
		{
			Self.OtherPlayer = Game::Mio;
			Self.MetalMesh.SetHiddenInGame(false);
			Self.CrystalMesh.SetHiddenInGame(true);
			USummitDecimatorTopdownPlayerTrapEffectsHandler::Trigger_OnMetalTrapped(Owner);
			USummitDecimatorTopdownEffectsHandler::Trigger_OnTrapMetalTrapped(Decimator);
		}


		// immobilize player movement
		UHazeCapsuleCollisionComponent CapsuleComponent = UHazeCapsuleCollisionComponent::Get(Self.Target);
		PlayerCollisionProfileName = CapsuleComponent.GetCollisionProfileName();
		CapsuleComponent.SetCollisionProfileName(n"PlayerCharacterAlternate");
		Self.Target.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonJump, this);
		Self.Target.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonSprint, this);
		Self.Target.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonDash, this);
		Self.Target.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonRoll, this);
		Self.Target.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonAcidSpray, this);
		Self.Target.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonAirGlide, this);
		Self.Target.ApplySettings(TeenDragonMovementSettingsDecimatorPlayerTrapOverride, this, EHazeSettingsPriority::Override);
		bIsPlayerBlocked = true;

		Self.SetActorEnableCollision(true);
		Self.TeleportActor(Self.Target.ActorLocation, Self.GetActorRotation(), this);
		
		if (bDoDisplaceOtherPlayer)
		{
			FVector ToOtherPlayer = (Self.OtherPlayer.ActorLocation - Owner.ActorLocation);
			UHazeCapsuleCollisionComponent OtherCapsuleComponent = UHazeCapsuleCollisionComponent::Get(Self.OtherPlayer);
			OtherCapsuleComponent.SetCollisionProfileName(n"PlayerCharacterAlternate");
			FVector Dir = ToOtherPlayer.GetSafeNormal2D();
			FTeenDragonStumble Stumble;
			Stumble.Duration = 0.73;
			Stumble.Move = Dir * 1000;
			Stumble.Apply(Self.OtherPlayer);
			Self.OtherPlayer.SetActorRotation((-Stumble.Move).ToOrientationQuat());
			bDisplacedOtherPlayer = true;
		}

		Self.Target.PlayForceFeedback(Self.PlayerTrapForceFeedback, false, true, this, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (!bHasTelegraphStopped) // Stopped because of phase change or player death. Destroy in midair.
			USummitDecimatorTopdownPlayerTrapEffectsHandler::Trigger_OnTelegraphAborted(Owner);

		RestorePlayerMovement();
		CrumbRestoreOtherPlayerCollisionProfile();

		Self.SetActorHiddenInGame(true);
		bIsDestroyed = false;
		bHasTelegraphStopped = false;
		EDamageType DamageType = Self.OtherPlayer == Game::Zoe ? EDamageType::Impact : EDamageType::Acid;
		HealthComp.TakeDamage(100.0, DamageType, Owner);
	}

	// Crumbed by call from OnDeactivated
	private void RestorePlayerMovement()
	{
		if (bIsPlayerBlocked)
		{
			Self.SetActorEnableCollision(false);
			UHazeCapsuleCollisionComponent CapsuleComponent = UHazeCapsuleCollisionComponent::Get(Self.Target);
			CapsuleComponent.SetCollisionProfileName(PlayerCollisionProfileName);
			Self.Target.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonJump, this);
			Self.Target.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonSprint, this);
			Self.Target.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonDash, this);
			Self.Target.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonRoll, this);
			Self.Target.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonAcidSpray, this);
			Self.Target.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonAirGlide, this);
			Self.Target.ClearSettingsByInstigator(this);
			bIsPlayerBlocked = false;
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbRestoreOtherPlayerCollisionProfile()
	{
		UHazeCapsuleCollisionComponent OtherCapsuleComponent = UHazeCapsuleCollisionComponent::Get(Self.OtherPlayer);
		OtherCapsuleComponent.SetCollisionProfileName(PlayerCollisionProfileName);
		bDisplacedOtherPlayer = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl() && ActiveDuration > TelegraphDuration + 0.73 && bDisplacedOtherPlayer)
			CrumbRestoreOtherPlayerCollisionProfile();

		if (ActiveDuration < TelegraphDuration)
		{
			FHazeFrameForceFeedback FrameForceFeedback;
			FrameForceFeedback.LeftMotor = Math::Abs(Math::Sin(Time::GameTimeSeconds));
			FrameForceFeedback.RightMotor = Math::Abs(Math::Sin(Time::GameTimeSeconds));
			Self.Target.SetFrameForceFeedback(FrameForceFeedback, Intensity = 0.1);

		}

		if (ActiveDuration > TelegraphDuration - 0.75 && !bHasTelegraphStopped) // time dependency in networked, might telegraph while trap has already become active
		{
			USummitDecimatorTopdownPlayerTrapEffectsHandler::Trigger_OnTelegraphStopped(Owner, FSummitDecimatorTopdownPlayerTrapTelegraphParams(Self.Target));
			USummitDecimatorTopdownEffectsHandler::Trigger_OnTrapTelegraphStopped(Decimator, FSummitDecimatorTopdownPlayerTrapTelegraphParams(Self.Target));
			bHasTelegraphStopped = true;
		}
		
		if (HasControl() && ActiveDuration > TelegraphDuration && !bIsPlayerBlocked)
			EnableTrappingControl();

		// Follow player movement
		if (bIsPlayerBlocked)
			Self.TeleportActor(Self.Target.ActorLocation, Self.GetActorRotation(), this);
		else
			UpdateProjectile(DeltaTime);
	}
	
	FVector LandTangent;
	FVector PrevCurveLoc;
	FVector PrevOffset;
	FVector TargetLocation;
	void UpdateProjectile(float DeltaTime)
	{		
		// Local movement 
		float FlightDuration = ActiveDuration;
		float TotalFlightDuration = 2.0;
		float Alpha = FlightDuration / TotalFlightDuration;
		if (Alpha > 1.0) // Skip. Prevent scaling bug.
		{
			Self.ProjectileMesh.SetHiddenInGame(true, true);
			Self.ProjectileMesh.SetRelativeLocation(FVector::ZeroVector);
			return;
		}

		FVector NewLoc = BezierCurve::GetLocation_2CP(
			Self.LaunchLocation,
			Self.LaunchLocation + Self.LaunchVelocity,
		 	TargetLocation - LandTangent,
			Self.Target.ActorCenterLocation,
			Alpha);

// #if EDITOR
// 		BezierCurve::DebugDraw_2CP(
// 			Self.LaunchLocation,
// 			Self.LaunchLocation + Self.LaunchVelocity,
// 		 	TargetLocation - LandTangent,
// 			Self.Target.ActorCenterLocation);
// #endif

		// Add a slight corkscrewish local offset around the curve trajectory.
		FVector LocalOffset;
		if (PrevCurveLoc != FVector::ZeroVector && Alpha < 1)
		{
			// Define a local space at the current curve point
			FVector Tangent = (NewLoc - PrevCurveLoc).GetSafeNormal();
			FVector RightVector = FVector::UpVector.CrossProduct(Tangent);
			FVector NormalVector = Tangent.CrossProduct(RightVector);
			
			// Reach maximum amplitude at Alpha = 0.5 and then return to 0 at Alpha = 1.0.
			float Amplitude = 1 - Math::Square(1 - 2*Alpha);
			Amplitude *= 100;
			
			// Circle planar to the curve tangent.
			LocalOffset += NormalVector * Amplitude * Math::Sin(Alpha*5);
			LocalOffset += RightVector * Amplitude * Math::Cos(Alpha*5);
		
			PrevOffset = LocalOffset;
			FRotator ActorRotation = ( (NewLoc + LocalOffset) - Self.ProjectileMesh.WorldLocation).Rotation();
			Self.ProjectileMesh.SetWorldRotation(ActorRotation);
		}
		
		float Scale = Math::EaseIn(0.05, 0.25, Alpha, 1);
		Self.ProjectileMesh.SetWorldScale3D(FVector(1,1,1)*Scale);
		
		PrevCurveLoc = NewLoc;
		Self.ProjectileMesh.SetWorldLocation(NewLoc + LocalOffset);
	}
};